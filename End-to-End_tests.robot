*** Settings ***
Documentation    End to End Scenario Testing
Test Teardown     After tests
Test Setup    Before tests
Suite Setup       Connect To Database    psycopg2    ${DBBRTName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
Suite Teardown    Disconnect From Database
Library    OperatingSystem 
Library    AMQPMsg
Library    LogUtils
Library    CDRFileUtils
Library    DatabaseLibrary

*** Variables ***
${correct_processed_msg}        CDR was processed succesfully 
${TINTEGR01_PATH}    ${CURDIR}/test_data/TINTEGR01_testdata.csv
${TINTEGR02_PATH}    ${CURDIR}/test_data/TINTEGR02_testdata.csv
${TINTEGR03_PATH}    ${CURDIR}/test_data/TINTEGR03_testdata.csv
${TINTEGR04_PATH}    ${CURDIR}/test_data/TINTEGR04_testdata.csv
${TINTEGR05_PATH}    ${CURDIR}/test_data/TINTEGR05_testdata.csv
${TINTEGR06_PATH}    ${CURDIR}/test_data/TINTEGR06_testdata.csv
${BRT_logs_file}    /var/log/brt.log
${amqp_host}    127.0.0.1
${amqp_port}    10231
${amqp_user}    tester
${amqp_pass}    123
${amqp_vhost}    TestVhost
${amqp_exchange}    X_BRT
${amqp_routing_key}    cdr.brt
${DBHost}         localhost
${DBBRTName}         bd_brt_name
${DBHRSName}         bd_hrs_name
${DBPass}         12345
${DBPort}         5432
${DBUser}         tester

** Test cases ***
TINTEGR01 validation
    [Documentation]    Эмуляция исходящего звонка абонента "Ромашки" с тарифом "Классика" другому абоненту "Ромашки" длительностью 1 минуту
    Connect To Database    psycopg2    ${DBBRTName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${calls}=    Parse Csv Cdr    ${TINTEGR01_PATH}
    ${balance_before}=    Get subscriber balance    ${calls.served_msisdn}
    Send CDR ${TINTEGR01_PATH}  to BRT
    Should Appear In Logs    ${correct_processed_msg}
    ${balance_after}=    Get subscriber balance    ${calls.served_msisdn}
    Disconnect From Database
    Connect To Database    psycopg2    ${DBHRSName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${price_per_min}=    Get call price per min    11    ${calls.call_type}    internal
    Disconnect From Database
    ${expected_balance}=    Evaluate    ${balance_before}-${price_per_min}
    Should Be Equal As Numbers    ${balance_after}    ${expected_balance}

TINTEGR02 validation
    [Documentation]    Эмуляция исходящего звонка абонента "Ромашки" с тарифом "Классика" абоненту другого оператора длительностью 1 минуту
    Connect To Database    psycopg2    ${DBBRTName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${calls}=    Parse Csv Cdr    ${TINTEGR02_PATH}
    ${balance_before}=    Get subscriber balance    ${calls.served_msisdn}
    Send CDR ${TINTEGR02_PATH}  to BRT
    Should Appear In Logs    ${correct_processed_msg}
    ${balance_after}=    Get subscriber balance    ${calls.served_msisdn}
    Disconnect From Database
    Connect To Database    psycopg2    ${DBHRSName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${price_per_min}=    Get call price per min    11    ${calls.call_type}    external
    Disconnect From Database
    ${expected_balance}=    Evaluate    ${balance_before}-${price_per_min}
    Should Be Equal As Numbers    ${balance_after}    ${expected_balance}

TINTEGR03 validation
    [Documentation]    Эмуляция входящего звонка абонента "Ромашки" с тарифом "Классика" от другого абонента "Ромашки" длительностью 1 минуту
    Connect To Database    psycopg2    ${DBBRTName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${calls}=    Parse Csv Cdr    ${TINTEGR03_PATH}
    ${balance_before}=    Get subscriber balance    ${calls.served_msisdn}
    Send CDR ${TINTEGR03_PATH}  to BRT
    Should Appear In Logs    ${correct_processed_msg}
    ${balance_after}=    Get subscriber balance    ${calls.served_msisdn}
    Disconnect From Database
    Connect To Database    psycopg2    ${DBHRSName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${price_per_min}=    Get call price per min    11    ${calls.call_type}    external
    Disconnect From Database
    ${expected_balance}=    Evaluate    ${balance_before}-${price_per_min}
    Should Be Equal As Numbers    ${balance_after}    ${expected_balance}

TINTEGR04 validation
    [Documentation]    Эмуляция исходящего звонка абонента "Ромашки" с тарифом "Помесячный" другому абоненту "Ромашки" длительностью 1 минуту 
    Connect To Database    psycopg2    ${DBBRTName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${calls}=    Parse Csv Cdr    ${TINTEGR04_PATH}
    ${balance_before}=    Get subscriber balance    ${calls.served_msisdn}
    Connect To Database    psycopg2    ${DBHRSName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${rest_before}=    Get subscriber rest of minutes    ${calls.served_msisdn}
    Disconnect From Database
    Send CDR ${TINTEGR04_PATH}  to BRT
    Should Appear In Logs    ${correct_processed_msg}
    ${balance_after}=    Get subscriber balance    ${calls.served_msisdn}
    Disconnect From Database
    Connect To Database    psycopg2    ${DBHRSName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${price_per_min}=    Get call price per min    12    ${calls.call_type}    internal
    ${rest_after}=    Get subscriber rest of minutes    ${calls.served_msisdn}
    Disconnect From Database
    ${expected_balance}=    Evaluate    ${balance_before}-${price_per_min}
    ${expected_rest}=    Evaluate    ${rest_before}-${1}
    Should Be Equal As Numbers    ${balance_after}    ${expected_balance}
    Should Be Equal As Numbers    ${rest_before}    ${expected_rest}

TINTEGR05 validation
    [Documentation]    Эмуляция исходящего звонка абонента "Ромашки" с тарифом "Помесячный" и отсутствием минут по тарифу другому абоненту "Ромашки" длительностью 1 минуту
    Connect To Database    psycopg2    ${DBBRTName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${calls}=    Parse Csv Cdr    ${TINTEGR05_PATH}
    ${balance_before}=    Get subscriber balance    ${calls.served_msisdn}
    Connect To Database    psycopg2    ${DBHRSName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${rest_before}=    Get subscriber rest of minutes    ${calls.served_msisdn}
    Disconnect From Database
    Send CDR ${TINTEGR05_PATH}  to BRT
    Should Appear In Logs    ${correct_processed_msg}
    ${balance_after}=    Get subscriber balance    ${calls.served_msisdn}
    Disconnect From Database
    Connect To Database    psycopg2    ${DBHRSName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${price_per_min}=    Get call price per min    11    ${calls.call_type}    internal
    ${rest_after}=    Get subscriber rest of minutes    ${calls.served_msisdn}
    Disconnect From Database
    ${expected_balance}=    Evaluate    ${balance_before}-${price_per_min}
    Should Be Equal As Numbers    ${balance_after}    ${expected_balance}
    Should Be Equal As Numbers    ${rest_before}    ${rest_after}

TINTEGR06 validation
    [Documentation]    Эмуляция исходящего звонка абонента "Ромашки" с тарифом "Помесячный" и отсутствием минут по тарифу абоненту другого оператора длительностью 1 минуту 
    ${calls}=    Parse Csv Cdr    ${TINTEGR05_PATH}
    ${balance_before}=    Get subscriber balance    ${calls.served_msisdn}
    Connect To Database    psycopg2    ${DBHRSName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${rest_before}=    Get subscriber rest of minutes    ${calls.served_msisdn}
    Disconnect From Database
    Send CDR ${TINTEGR05_PATH}  to BRT
    Should Appear In Logs    ${correct_processed_msg}
    ${balance_after}=    Get subscriber balance    ${calls.served_msisdn}
    Disconnect From Database
    Connect To Database    psycopg2    ${DBHRSName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
    ${price_per_min}=    Get call price per min    11    ${calls.call_type}    external
    ${rest_after}=    Get subscriber rest of minutes    ${calls.served_msisdn}
    Disconnect From Database
    ${expected_balance}=    Evaluate    ${balance_before}-${price_per_min}
    Should Be Equal As Numbers    ${balance_after}    ${expected_balance}
    Should Be Equal As Numbers    ${rest_before}    ${rest_after}

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

Get subscriber balance
    [Documentation]    Получение баланса абонента из БД
    [Arguments]    ${msisdn}
    ${res}=    Query    select s.balance from subscribers s where s.served_msisdn = ${msisdn}
    RETURN    ${res}

Get call price per min
    [Arguments]    ${plan_id}    ${call_type}    ${dest_type}
    [Documentation]    Получение стоимости звонка из БД HRS
    ${res}=    Query    select t.call_price from tariff_call_prices t where t.plan_id = ${plan_id} and t.call_type = ${call_type} and t.destination_type = ${dest_type};
    RETURN    ${res}

Get subscriber rest of minutes
    [Arguments]    ${msisdn}
    [Documentation]    Получение остатка минут по тарифу абонента из БД HRS
    ${res}=    Query    select h.minutes_left from hrs_info h where h.msisdn = ${msisdn};
    RETURN    ${res}
