#include <iostream>
#include <stdio.h>
#include <string.h>
#include <tchar.h>

//заголовки для использования анклава
#include "sgx_urts.h"
#include "sgx_tseal.h"
#include "Enclave_lab3_u.h"

#define ENCLAVE_FILE _T("Enclave_lab3.signed.dll") //указание, с каким dll работать 
#define BUF_LEN 100 //длина буфера между небезопасным приложением и анклавом

/*const char table[5][31] = {"000000000000000000000000000000",
                            "111111111111111111111111111111",
                            "222222222222222222222222222222",
                            "333333333333333333333333333333",
                            "444444444444444444444444444444" };

void getElementByIndex(char* buffer, size_t len, size_t index) {

    if (index >= 0 && index < 5) {
        const char* data_ptr = table[index];
        memcpy(buffer, data_ptr, strlen(data_ptr + 1));
    }
    else {
        memset(buffer, 0, strlen(table[0]));
    }
    return;
}*/


//основной код, который итеративно запрашивает от пользователя номер индекса в таблице и печатает индекс на экране
int main()
{

    //создание и инициализация анклава
    sgx_enclave_id_t eid;
    sgx_status_t ret = SGX_SUCCESS;
    sgx_launch_token_t token = { 0 };
    int updated = 0;

    //анклав создается и проверяется, правильно ли он был создан
    ret = sgx_create_enclave(ENCLAVE_FILE, SGX_DEBUG_FLAG, &token, &updated, &eid, NULL);
    if (ret != SGX_SUCCESS) {
        printf("App: error %#x, failed to create enclave.\n", ret);
        return -1;
    }

    //изначальное тело функции
    char buffer[BUF_LEN] = { 0 };
    while (true) {
        printf("Enter an index or -1 to exit\t");
        int index = -1;
        scanf_s("%d", &index);
        if (index == -1) {
            break;
        }
        getElementByIndex(eid, buffer, BUF_LEN, index);
        //getElementByIndex(buffer, BUF_LEN, index);
        printf("%s\n*************************************\n\n", buffer);
    }

    //выгрузка анклава
    if (SGX_SUCCESS != sgx_destroy_enclave(eid))
        return -1;
    return 0;
}