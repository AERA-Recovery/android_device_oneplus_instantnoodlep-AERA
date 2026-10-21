/* SPDX-License-Identifier: Apache-2.0 */
#include <stdint.h>

int __real_qrtr_publish(int socket, uint32_t service, uint16_t version, uint16_t instance);

int __wrap_qrtr_publish(int socket, uint32_t service, uint16_t version, uint16_t instance)
{
    /* The external SDX55 requests the MDM MPSS RFSA service, not the AP variant. */
    return __real_qrtr_publish(socket, service, service == 4096 ? 3 : version, instance);
}
