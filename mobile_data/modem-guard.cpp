/* SPDX-License-Identifier: Apache-2.0 */
#include "qmi.hpp"
#include <cutils/properties.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/statfs.h>
#include <sys/ioctl.h>
#include <sys/prctl.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <linux/capability.h>
#include <linux/fs.h>
#include <linux/filter.h>
#include <linux/seccomp.h>
#include <linux/audit.h>
#include <cstddef>
#include <sched.h>
#include <fcntl.h>
#include <sys/file.h>
#include <grp.h>
#include <signal.h>
#include <thread>

using namespace aera::mobile;
namespace {
const std::string base="/tmp/aera-cellular/modem";
const std::string root=base+"/root";
volatile sig_atomic_t stopped=0;
void Stop(int){stopped=1;}
void Fail(const std::string &message){throw std::runtime_error(message+": "+strerror(errno));}
void Dir(const std::string &path) {
  for(size_t i=1;i<=path.size();++i)if(i==path.size()||path[i]=='/')
    if(mkdir(path.substr(0,i).c_str(),0700)&&errno!=EEXIST)Fail("mkdir "+path);
}
std::string Read(const std::string &path) {
  Fd fd(open(path.c_str(),O_RDONLY|O_CLOEXEC));char buffer[128];
  const ssize_t size=fd.get()<0?-1:read(fd.get(),buffer,sizeof(buffer));
  std::string value=size>0?std::string(buffer,size):"";
  while(!value.empty()&&(value.back()=='\n'||value.back()=='\r'))value.pop_back();
  return value;
}
std::string ModemState() {
  for(int i=0;i<64;++i) {
    const auto path="/sys/bus/msm_subsys/devices/subsys"+std::to_string(i);
    if(Read(path+"/name")=="esoc0")return Read(path+"/state");
  }
  return {};
}
void Bind(const std::string &from,const std::string &to,bool readonly=true) {
  if(mount(from.c_str(),to.c_str(),nullptr,MS_BIND,nullptr))Fail("bind "+from);
  if(readonly&&mount(nullptr,to.c_str(),nullptr,MS_BIND|MS_REMOUNT|MS_RDONLY|MS_NOSUID|MS_NODEV,nullptr))
    Fail("read-only bind "+from);
}
void Character(const std::string &from,const std::string &to) {
  struct stat s{};if(stat(from.c_str(),&s)||!S_ISCHR(s.st_mode))return;
  if(mknod(to.c_str(),S_IFCHR|0600,s.st_rdev)&&errno!=EEXIST)Fail("device "+to);
}
void MhiDevices() {
  for(int pipe:{0,2,10,14,16,22,32}) {
    const auto name="mhi_0306_02.01.00_pipe_"+std::to_string(pipe);
    Character("/dev/"+name,root+"/dev/"+name);
  }
}
void Snapshot(const std::string &name,uint64_t &total) {
  Fd in(open(("/dev/block/bootdevice/by-name/"+name).c_str(),O_RDONLY|O_CLOEXEC));
  if(in.get()<0)Fail("read-only source "+name);
  struct stat s{};uint64_t size=0;
  if(fstat(in.get(),&s)||!S_ISBLK(s.st_mode)||ioctl(in.get(),BLKGETSIZE64,&size))Fail("source size "+name);
  if(!size||size>64*1024*1024||size+total>160*1024*1024)
    throw std::runtime_error("RAM snapshot size limit exceeded");
  Fd out(open((root+"/dev/block/bootdevice/by-name/"+name).c_str(),O_WRONLY|O_CREAT|O_EXCL|O_CLOEXEC,0600));
  if(out.get()<0)Fail("RAM destination "+name);
  Bytes buffer(1024*1024);uint64_t copied=0;
  while(copied<size) {
    const auto amount=std::min<uint64_t>(buffer.size(),size-copied);
    ssize_t n=read(in.get(),buffer.data(),amount);
    if(n<0&&errno==EINTR)continue;
    if(n<=0)Fail("snapshot read "+name);
    ssize_t done=0;
    while(done<n) {
      ssize_t w=write(out.get(),buffer.data()+done,n-done);
      if(w<0&&errno==EINTR)continue;
      if(w<=0)Fail("RAM snapshot write");done+=w;
    }
    copied+=n;
  }
  total+=size;
}
void ProcFile(const std::string &path) {
  Fd in(open(path.c_str(),O_RDONLY|O_CLOEXEC));if(in.get()<0)return;
  Dir(root+path.substr(0,path.rfind('/')));
  Fd out(open((root+path).c_str(),O_WRONLY|O_CREAT|O_EXCL|O_CLOEXEC,0400));
  if(out.get()<0)Fail("private proc file");
  char buffer[4096];size_t total=0;
  for(;;) {
    ssize_t n=read(in.get(),buffer,sizeof(buffer));
    if(n<0&&errno==EINTR)continue;
    if(n==0)break;if(n<0)Fail("proc read");
    total+=n;if(total>65536)throw std::runtime_error("proc copy limit exceeded");
    ssize_t done=0;
    while(done<n) {
      ssize_t w=write(out.get(),buffer+done,n-done);
      if(w<0&&errno==EINTR)continue;
      if(w<=0)Fail("proc copy");done+=w;
    }
  }
}
void Setup() {
  struct statfs fs{};
  if(statfs("/tmp",&fs)||(fs.f_type!=0x01021994&&static_cast<unsigned long>(fs.f_type)!=0x858458f6))
    throw std::runtime_error("Temporary directory is not RAM-backed");
  if(unshare(CLONE_NEWNS)||mount(nullptr,"/",nullptr,MS_REC|MS_PRIVATE,nullptr))Fail("private mounts");
  Dir(base+"/vendor");Dir(root);
  char suffix[PROPERTY_VALUE_MAX]{};property_get("ro.boot.slot_suffix",suffix,"");
  if(strcmp(suffix,"_a")&&strcmp(suffix,"_b"))throw std::runtime_error("Invalid boot slot");
  const std::string vendor=std::string("/dev/block/mapper/vendor")+suffix;
  const unsigned long flags=MS_RDONLY|MS_NODEV|MS_NOSUID;
  if(mount(vendor.c_str(),(base+"/vendor").c_str(),"erofs",flags,nullptr)&&
      mount(vendor.c_str(),(base+"/vendor").c_str(),"ext4",flags,"noload"))Fail("read-only ROM vendor mount");
  for(const char *name:{"mdm_helper","ks"})
    if(access((base+"/vendor/bin/"+name).c_str(),X_OK))Fail("missing OEM helper");
  const char *environment=getenv("AERA_CELLULAR_FIRMWARE");
  const std::string firmware=environment?environment:"";
  if(firmware.empty()||firmware.front()!='/'||access((firmware+"/sdx55m/sbl1.mbn").c_str(),R_OK))
    throw std::runtime_error("SDX55 firmware is unavailable");
  if(mount("tmpfs",root.c_str(),"tmpfs",MS_NOSUID,"size=192m,mode=0700"))Fail("RAM root");
  for(const char *path:{"/vendor","/system","/sys","/proc","/tmp","/dev/socket","/dev/__properties__",
      "/dev/block/bootdevice/by-name","/firmware/image","/data/vendor/tombstones"})Dir(root+path);
  Bind(base+"/vendor",root+"/vendor");
  Bind("/system",root+"/system");Bind("/sys",root+"/sys");
  Bind(firmware.substr(0,firmware.rfind('/')),root+"/vendor/firmware_mnt");
  Bind(firmware,root+"/firmware/image");
  Bind("/dev/__properties__",root+"/dev/__properties__");
  // No live /proc or physical block nodes enter the OEM helper's root.
  for(const char *path:{"/proc/oplusVersion/prjName","/proc/oplusVersion/oplusBootmode",
      "/proc/oplusVersion/engVersion","/proc/oplusVersion/pcbVersion","/proc/oplusVersion/RFType",
      "/proc/oplusVersion/feature","/proc/oplusVersion/isConfidential","/proc/oplus_rf/rf_cable",
      "/proc/version","/proc/cmdline"})ProcFile(path);
  for(const char *name:{"null","zero","random","urandom","esoc-0","subsys_esoc0"})
    Character(std::string("/dev/")+name,root+"/dev/"+name);
  Fd log(open((root+"/dev/socket/logdw").c_str(),O_WRONLY|O_CREAT|O_CLOEXEC,0600));
  if(log.get()<0)Fail("log socket target");
  Bind("/dev/socket/logdw",root+"/dev/socket/logdw",false);
  uint64_t total=0;
  for(const char *name:{"mdm1m9kefs1","mdm1m9kefs2","mdm1m9kefs3","mdm1m9kefsc","mdmddr",
      "mdm1oemnvbktmp","mdm_oem_stanvbk","mdm_oem_dycnvbk"})Snapshot(name,total);
  MhiDevices();
  printf("OEM helper ready: %llu bytes of RAM snapshots; physical NV is read-only\n",
      static_cast<unsigned long long>(total));fflush(stdout);
}
void Execute(bool request=false,pid_t group=0) {
  if(setpgid(0,group))Fail("helper process group");
  if(chroot(root.c_str())||chdir("/"))Fail("helper root");
  for(int fd=3;fd<4096;++fd)close(fd);
  if(setgroups(0,nullptr))Fail("drop groups");
  for(int cap=0;cap<=40;++cap)
    if(prctl(PR_CAPBSET_DROP,cap,0,0,0)&&errno!=EINVAL)Fail("drop capability bound");
  __user_cap_header_struct header{_LINUX_CAPABILITY_VERSION_3,0};__user_cap_data_struct data[2]{};
  if(syscall(SYS_capset,&header,data)||prctl(PR_SET_NO_NEW_PRIVS,1,0,0,0))Fail("drop capabilities");
  // The kernel lacks PID namespaces: keep all descendants in the supervised group.
  struct sock_filter filter[]={
    BPF_STMT(BPF_LD|BPF_W|BPF_ABS,offsetof(struct seccomp_data,arch)),
    BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K,AUDIT_ARCH_AARCH64,1,0),
    BPF_STMT(BPF_RET|BPF_K,SECCOMP_RET_KILL_PROCESS),
    BPF_STMT(BPF_LD|BPF_W|BPF_ABS,offsetof(struct seccomp_data,nr)),
    BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K,SYS_setsid,2,0),
    BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K,SYS_setpgid,1,0),
    BPF_STMT(BPF_RET|BPF_K,SECCOMP_RET_ALLOW),
    BPF_STMT(BPF_RET|BPF_K,SECCOMP_RET_ERRNO|EPERM)};
  struct sock_fprog program{static_cast<unsigned short>(sizeof(filter)/sizeof(filter[0])),filter};
  if(prctl(PR_SET_SECCOMP,SECCOMP_MODE_FILTER,&program))Fail("process group guard");
  if(request) {
    Fd control(open("/dev/subsys_esoc0",O_RDONLY|O_CLOEXEC));
    if(control.get()<0)Fail("request ESOC boot");
    puts("ESOC boot reference acquired");fflush(stdout);
    while(!stopped)std::this_thread::sleep_for(std::chrono::milliseconds(100));
    puts("Releasing ESOC normally while the image helper is alive");fflush(stdout);
    return;
  }
  setenv("LD_LIBRARY_PATH","/vendor/lib64:/system/lib64",1);
  execl("/vendor/bin/mdm_helper","/vendor/bin/mdm_helper",nullptr);Fail("execute OEM helper");
}
pid_t StartChild(bool request,pid_t group=0) {
  const pid_t child=fork();if(child<0)Fail("fork OEM helper");
  if(child==0) {
    try{Execute(request,group);_exit(0);}
    catch(const std::exception &e){fprintf(stderr,"OEM child: %s\n",e.what());_exit(1);}
  }
  return child;
}
void Release(pid_t &request,pid_t &helper,bool powered) {
  if(request>0) {
    kill(request,SIGTERM);
    int status=0;
    while(waitpid(request,&status,0)<0&&errno==EINTR){}
    powered|=WIFEXITED(status)&&WEXITSTATUS(status)==0;
    request=-1;
  }
  // Never interrupt subsystem shutdown or discard its backing files mid-flight.
  while(powered&&ModemState()!="OFFLINE")
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  if(helper>0) {
    kill(-helper,SIGKILL);kill(helper,SIGKILL);
    while(waitpid(-1,nullptr,0)>0||errno==EINTR){}
    helper=-1;
  }
}
}
int main(int argc,char **argv) {
  pid_t helper=-1,request=-1;bool powered=false;
  Fd lock;
  signal(SIGTERM,Stop);signal(SIGINT,Stop);signal(SIGHUP,Stop);
  try {
    const pid_t parent=getppid();
    if(prctl(PR_SET_PDEATHSIG,SIGTERM)||getppid()!=parent)return 1;
    const bool check=argc==2&&std::string(argv[1])=="--check";
    if(argc!=1&&!check)return 2;
    lock.reset(open("/tmp/aera-cellular-modem.lock",O_RDWR|O_CREAT|O_CLOEXEC|O_NOFOLLOW,0600));
    if(lock.get()<0||flock(lock.get(),LOCK_EX|LOCK_NB))Fail("modem supervisor lock");
    Setup();if(check||stopped)return 0;
    if(prctl(PR_SET_CHILD_SUBREAPER,1,0,0,0))Fail("child supervisor");
    helper=StartChild(false);
    bool failed=false;
    for(unsigned ticks=0;!stopped;++ticks) {
      MhiDevices();powered|=ModemState()=="ONLINE";
      siginfo_t info{};
      // Keep exited children waitable until Release so their PIDs cannot be reused.
      if(waitid(P_PID,helper,&info,WEXITED|WNOHANG|WNOWAIT)==0&&info.si_pid==helper) {
        fprintf(stderr,"OEM helper exited unexpectedly: %d\n",info.si_status);failed=true;break;
      }
      info={};
      if(request>0&&waitid(P_PID,request,&info,WEXITED|WNOHANG|WNOWAIT)==0&&info.si_pid==request) {
        fprintf(stderr,"ESOC reference exited unexpectedly: %d\n",info.si_status);
        failed=true;break;
      }
      if(ticks==20)request=StartChild(true,helper);
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    Release(request,helper,powered);
    puts("SDX55 helper stopped; private mounts and RAM snapshots released");return failed?1:0;
  }catch(const std::exception &e) {
    fprintf(stderr,"Modem supervisor: %s\n",e.what());
    Release(request,helper,powered);return 1;
  }
}
