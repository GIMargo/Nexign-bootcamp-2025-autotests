*** Settings ***
Documentation    CDR validation on BRT
Test Teardown     After tests
Test Setup    Before tests
Suite Setup       Connect To Database    psycopg2    ${DBName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
Suite Teardown    Disconnect From Database
Library    OperatingSystem 
Library    AMQPMsg
Library    LogUtils
Library    CDRFileUtils
Library    DatabaseLibrary

*** Variables ***
${correct_processed_msg}        CDR was processed succesfully 
${TUCBRT01_PATH}    ${CURDIR}/test_data/TUCBRT01_testdata.csv
${TUCBRT02_PATH}    ${CURDIR}/test_data/TUCBRT02_testdata.csv
${TUCBRT03_PATH}    ${CURDIR}/test_data/TUCBRT03_testdata.csv
${TUCBRT04_PATH}    ${CURDIR}/test_data/TUCBRT04_testdata.csv
${TUCBRT05_PATH}    ${CURDIR}/test_data/TUCBRT05_testdata.csv
${TUCBRT06_PATH}    ${CURDIR}/test_data/TUCBRT06_testdata.csv
${TUCBRT07_PATH}    ${CURDIR}/test_data/TUCBRT07_testdata.csv
${TUCBRT08_PATH}    ${CURDIR}/test_data/TUCBRT08_testdata.csv
${TUCBRT09_PATH}    ${CURDIR}/test_data/TUCBRT09_testdata.csv
${TUCBRT10_PATH}    ${CURDIR}/test_data/TUCBRT10_testdata.csv
${BRT_logs_file}    /var/log/brt.log
${amqp_host}    127.0.0.1
${amqp_port}    10231
${amqp_user}    tester
${amqp_pass}    123
${amqp_vhost}    TestVhost
${amqp_exchange}    X_BRT
${amqp_routing_key}    cdr.brt
${DBHost}         localhost
${DBName}         bd_brt_name
${DBPass}         12345
${DBPort}         5432
${DBUser}         tester

*** Test cases ***
Correct Romashka CDR validation
    [Documentation]    Проверка обработки CDR со звонками от абонентов "Ромашки" абонентам "Ромашки"
    Send CDR ${TUCBRT01_PATH} to BRT
    Should Appear In Logs    ${correct_processed_msg}
    @{calls}=    Parse Csv Cdr    ${TUCBRT01_PATH}
    FOR    ${call}    IN    ${calls}
        ${query}=    Convert Call Record into query    ${call.call_type}    ${call.served_msisdn}
        ...    ${call.second_msisdn}    ${call.start_time}    ${call.end_time}
        Check Row Count    ${query}    should be    ${1}
    END

NON Romashka CDR validation
    [Documentation]    Проверка обработки CDR со звонками между абонентами другого оператора
    Send CDR ${TUCBRT02_PATH} to BRT
    Should Appear In Logs    ${correct_processed_msg}
    @{calls}=    Parse Csv Cdr    ${TUCBRT02_PATH}
    FOR    ${call}    IN    ${calls}
        ${query}=    Convert Call Record into query    ${call.call_type}    ${call.served_msisdn}
        ...    ${call.second_msisdn}    ${call.start_time}    ${call.end_time}
        Check Row Count    ${query}    should be    ${0}
        Should Appear In Logs    Subscriber with msisdn ${call.served_msisdn} was not found
    END

Romashka with empty fields CDR validation
    [Documentation]    Проверка обработки CDR с пустыми значениями полей
    ${calls_size_before}=    Query    select select count(*) from calls;
    Send CDR ${TUCBRT03_PATH} to BRT
    Should Appear In Logs    ${correct_processed_msg}
    FOR    ${retry}    IN RANGE    10
        Should Appear In Logs   Empty field error
    END
    ${calls_size_after}=    Query    select select count(*) from calls;
    Should Be Equal As Integers    ${calls_size_before}    ${calls_size_after}

Romashka with invalid call type CDR validation
    [Documentation]    Проверка обработки CDR со звонками несуществующего типа вызова
    ${calls_size_before}=    Query    select select count(*) from calls;
    Send CDR ${TUCBRT04_PATH} to BRT
    Should Appear In Logs    ${correct_processed_msg}
    FOR    ${retry}    IN RANGE    10
        Should Appear In Logs   Invalid call type error
    END
    ${calls_size_after}=    Query    select select count(*) from calls;
    Should Be Equal As Integers    ${calls_size_before}    ${calls_size_after}

Romashka with negative duration calls CDR validation
    [Documentation]    Проверка обработки CDR со звонками отрицательной продолжительности
    ${calls_size_before}=    Query    select select count(*) from calls;
    Send CDR ${TUCBRT05_PATH} to BRT
    Should Appear In Logs    ${correct_processed_msg}
    FOR    ${retry}    IN RANGE    10
        Should Appear In Logs   Negative call duration error
    END
    ${calls_size_after}=    Query    select select count(*) from calls;
    Should Be Equal As Integers    ${calls_size_before}    ${calls_size_after}


Romashka with identical msisdn CDR validation
    [Documentation]    Проверка обработки CDR со звонками абонента самому себе
    ${calls_size_before}=    Query    select select count(*) from calls;
    Send CDR ${TUCBRT06_PATH} to BRT
    Should Appear In Logs    ${correct_processed_msg}
    @{calls}=    Parse Csv Cdr    ${TUCBRT06_PATH}
    FOR    ${call}    IN    ${calls}
        Should Appear In Logs    Identical msisdn error ${call.served_msisdn}
    END
    ${calls_size_after}=    Query    select select count(*) from calls;
    Should Be Equal As Integers    ${calls_size_before}    ${calls_size_after}

Romashka future calls CDR validation
    [Documentation]    Проверка обработки CDR со звонками из будущего
    ${calls_size_before}=    Query    select select count(*) from calls;
    Send CDR ${TUCBRT07_PATH} to BRT
    Should Appear In Logs    ${correct_processed_msg}
    FOR    ${retry}    IN RANGE    10
        Should Appear In Logs   Incorrect date and time record
    END
    ${calls_size_after}=    Query    select select count(*) from calls;
    Should Be Equal As Integers    ${calls_size_before}    ${calls_size_after}

Empty file validation
    [Documentation]    Проверка обработки пустого файла
    ${calls_size_before}=    Query    select select count(*) from calls;
    Send CDR ${TUCBRT08_PATH} to BRT
    Should Appear In Logs    Empty CDR-file error
    ${calls_size_after}=    Query    select select count(*) from calls;
    Should Be Equal As Integers    ${calls_size_before}    ${calls_size_after}

One Romashka call record validation
    [Documentation]    Проверка обработки файла с одной записью о звонке
    Send CDR ${TUCBRT09_PATH} to BRT
    Should Appear In Logs    ${correct_processed_msg}
    @{calls}=    Parse Csv Cdr    ${TUCBRT09_PATH}
    FOR    ${call}    IN    ${calls}
        ${query}=    Convert Call Record into query    ${call.call_type}    ${call.served_msisdn}
        ...    ${call.second_msisdn}    ${call.start_time}    ${call.end_time}
        Check Row Count    ${query}    should be    ${1}
    END

Eleven Romashka call records validation
    [Documentation]    Проверка обработки файла с 11 записями о звонке
    Send CDR ${TUCBRT10_PATH} to BRT
    Should Appear In Logs    ${correct_processed_msg}
    @{calls}=    Parse Csv Cdr    ${TUCBRT10_PATH}
    FOR    ${call}    IN    ${calls}
        ${query}=    Convert Call Record into query    ${call.call_type}    ${call.served_msisdn}
        ...    ${call.second_msisdn}    ${call.start_time}    ${call.end_time}
        Check Row Count    ${query}    should be    ${1}
    END    

*** Keywords ***
Before tests
    Init AMQP connection    ${amqp_host}  ${amqp_port}   ${amqp_user}  ${amqp_pass}   ${amqp_vhost}
    Set amqp destination    ${amqp_exchange}        ${amqp_routing_key}
    Set Logs Source    ${BRT_logs_file}
    Set Logs Type    file

After tests
    close amqp connection

Send CDR ${path} to BRT
    [Documentation]    Отправка CDR в BRT
    File Should Exist    ${path}
    ${content}=    Get File    ${path}
    Send Amqp Msg    ${content}

Convert Call Record into query
    [Documentation]    Формирование запроса на получение информации об абоненте
    [Arguments]    ${call_type}    ${served_msisdn}    ${second_msisdn}    ${start_time}    ${end_time}
    ${query}=    Set Variable    select * from calls c where c.call_type = ${call_type} and c.served_msisdn = ${served_msisdn} and 
        ...c.second_msisdn = ${second_msisdn} and c.start_time = ${start_time} and 
        ...c.end_time = ${end_time};
    RETURN    ${query}
