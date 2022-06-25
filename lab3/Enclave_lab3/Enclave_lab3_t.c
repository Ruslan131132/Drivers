#include "Enclave_lab3_t.h"

#include "sgx_trts.h" /* for sgx_ocalloc, sgx_is_outside_enclave */
#include "sgx_lfence.h" /* for sgx_lfence */

#include <errno.h>
#include <mbusafecrt.h> /* for memcpy_s etc */
#include <stdlib.h> /* for malloc/free etc */

#define CHECK_REF_POINTER(ptr, siz) do {	\
	if (!(ptr) || ! sgx_is_outside_enclave((ptr), (siz)))	\
		return SGX_ERROR_INVALID_PARAMETER;\
} while (0)

#define CHECK_UNIQUE_POINTER(ptr, siz) do {	\
	if ((ptr) && ! sgx_is_outside_enclave((ptr), (siz)))	\
		return SGX_ERROR_INVALID_PARAMETER;\
} while (0)

#define CHECK_ENCLAVE_POINTER(ptr, siz) do {	\
	if ((ptr) && ! sgx_is_within_enclave((ptr), (siz)))	\
		return SGX_ERROR_INVALID_PARAMETER;\
} while (0)

#define ADD_ASSIGN_OVERFLOW(a, b) (	\
	((a) += (b)) < (b)	\
)


typedef struct ms_getElementByIndex_t {
	char* ms_buffer;
	size_t ms_len;
	size_t ms_index;
} ms_getElementByIndex_t;

#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable: 4127)
#pragma warning(disable: 4200)
#pragma warning(disable: 4090)
#endif

static sgx_status_t SGX_CDECL sgx_getElementByIndex(void* pms)
{
	CHECK_REF_POINTER(pms, sizeof(ms_getElementByIndex_t));
	//
	// fence after pointer checks
	//
	sgx_lfence();
	ms_getElementByIndex_t* ms = SGX_CAST(ms_getElementByIndex_t*, pms);
	sgx_status_t status = SGX_SUCCESS;
	char* _tmp_buffer = ms->ms_buffer;
	size_t _tmp_len = ms->ms_len;
	size_t _len_buffer = _tmp_len;
	char* _in_buffer = NULL;

	CHECK_UNIQUE_POINTER(_tmp_buffer, _len_buffer);

	//
	// fence after pointer checks
	//
	sgx_lfence();

	if (_tmp_buffer != NULL && _len_buffer != 0) {
		if ( _len_buffer % sizeof(*_tmp_buffer) != 0)
		{
			status = SGX_ERROR_INVALID_PARAMETER;
			goto err;
		}
		if ((_in_buffer = (char*)malloc(_len_buffer)) == NULL) {
			status = SGX_ERROR_OUT_OF_MEMORY;
			goto err;
		}

		memset((void*)_in_buffer, 0, _len_buffer);
	}
	getElementByIndex(_in_buffer, _tmp_len, ms->ms_index);
	if (_in_buffer) {
		if (MEMCPY_S(_tmp_buffer, _len_buffer, _in_buffer, _len_buffer)) {
			status = SGX_ERROR_UNEXPECTED;
			goto err;
		}
	}

err:
	if (_in_buffer) free(_in_buffer);
	return status;
}

SGX_EXTERNC const struct {
	size_t nr_ecall;
	struct {void* call_addr; uint8_t is_priv; uint8_t is_switchless;} ecall_table[1];
} g_ecall_table = {
	1,
	{
		{(void*)(uintptr_t)sgx_getElementByIndex, 0, 0},
	}
};

SGX_EXTERNC const struct {
	size_t nr_ocall;
} g_dyn_entry_table = {
	0,
};


#ifdef _MSC_VER
#pragma warning(pop)
#endif
