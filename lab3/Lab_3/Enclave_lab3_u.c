#include "Enclave_lab3_u.h"
#include <errno.h>

typedef struct ms_getElementByIndex_t {
	char* ms_buffer;
	size_t ms_len;
	size_t ms_index;
} ms_getElementByIndex_t;

static const struct {
	size_t nr_ocall;
	void * func_addr[1];
} ocall_table_Enclave_lab3 = {
	0,
	{ NULL },
};

sgx_status_t getElementByIndex(sgx_enclave_id_t eid, char* buffer, size_t len, size_t index)
{
	sgx_status_t status;
	ms_getElementByIndex_t ms;
	ms.ms_buffer = buffer;
	ms.ms_len = len;
	ms.ms_index = index;
	status = sgx_ecall(eid, 0, &ocall_table_Enclave_lab3, &ms);
	return status;
}

