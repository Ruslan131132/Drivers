#ifndef ENCLAVE_LAB3_T_H__
#define ENCLAVE_LAB3_T_H__

#include <stdint.h>
#include <wchar.h>
#include <stddef.h>
#include "sgx_edger8r.h" /* for sgx_ocall etc. */


#define SGX_CAST(type, item) ((type)(item))

#ifdef __cplusplus
extern "C" {
#endif

#ifdef NO_HARDEN_EXT_WRITES
#define MEMCPY_S memcpy_s
#define MEMSET memset
#else
#define MEMCPY_S memcpy_verw_s
#define MEMSET memset_verw
#endif /* NO_HARDEN_EXT_WRITES */

void getElementByIndex(char* buffer, size_t len, size_t index);


#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif
