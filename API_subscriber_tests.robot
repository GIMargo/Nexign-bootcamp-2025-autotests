*** Settings ***
Documentation   API Testing subscriber role
Library    RequestsLibrary
Library    Collections
Library    MsisdnUtils

*** Variables ***
${host}             http://localhost:8000
${manager_login}    vasily-ivanych
${manager_password}  right-password

*** Test Cases ***
Subscriber Valid Auth
    [Documentation]    Авторизация абонента
    Authenticate as manager    ${manager_login}    ${manager_password}   
    ${msisdn}=    Get random Romashka msisdn
    ${response}=    Authenticate as subscriber ${msisdn}
    Dictionary Should Contain Key    ${response.headers}    accessToken
    
Pay the balance by subscriber
    [Documentation]    Пополнение баланса абонентом
    Authenticate as manager    ${manager_login}    ${manager_password}   
    ${msisdn}=    Get random Romashka msisdn
    ${balance_before}=    Get subscriber balance    ${msisdn}
    Authenticate as subscriber    ${msisdn}
    ${response}=    POST On Session    client_session    /api/v1/subscriber/pay     json='{"amount": 0.1}'
    Status Should Be    200    ${response}
    Dictionary Should Contain Key    ${response.headers}    paymentToken
    ${token}=    Get From Dictionary    ${response}    paymentToken
    Simulate Payment Confirmation    paymentToken
    ${balance_after}=    Get subscriber balance    ${msisdn}
    ${expected_balance}=    Evaluate    ${balance_before}+${0.1}
    Should Be Equal As Numbers    ${balance_after}    ${expected_balance}

    
*** Keywords ***

Try Authenticate with 
    [Documentation]    Авторизация с переданными msisdn
    [Arguments]    ${msisdn}
    ${response}=    POST  ${host} /api/v1/subscriber/auth    json='{"msisdn": "${msisdn}"}'
    RETURN ${response}

Authenticate as manager
    [Documentation]    Аутентификация и авторизация под ролью "менеджер" и создание сессии
    [Arguments]    ${login}    ${password}
    ${response}=    POST  ${host}/api/v1/manager/auth    json='{"login": "${login}", "password": "${password}"}'
    Status Should Be    200    ${response}
    Create Session    manager_session    ${host}    headers=${response.headers}

Authenticate as subscriber
    [Documentation]    Авторизация под ролью "абонент" и создание сессии
    [Arguments]    ${msisdn}
    ${response}=    POST  ${host}/api/v1/subscriber/auth    json='{"msisdn": "${msisdn}"}'
    Status Should Be    200    ${response}
    Create Session    subscriber_session    ${host}    headers=${response.headers}
    RETURN ${response}

Get random Romashka msisdn
    [Documentation]    Выбор случайного абонента "Ромашки"
    ${response}=    GET On Session    manager_session    /api/v1/manager/subscribers
    Status Should Be    200    ${response}
    ${subscriber}=  Evaluate  random.choice(${response.json()})  random
    ${msisdn}=    Get From Dictionary    ${subscriber}   msisdn
    RETURN ${msisdn}

Get subscriber info 
    [Documentation]    Получение информации о выбранном абоненте
    [Arguments]    ${msisdn}
    ${response}=    GET On Session    manager_session    /api/v1/manager/subscribers/${msisdn}
    Status Should Be    200    ${response}
    RETURN ${response.json()}


Get subscriber balance
    [Documentation]    Получение баланса выбранного абонента
    [Arguments]    ${msisdn}
    ${json}=    Get subscriber info    ${msisdn}
    ${balance}=    Get From Dictionary    ${json}    balance
    RETURN ${balance}

Simulate Payment Confirmation
    [Documentation]    Симуляция подтверждения оплаты абонента по токену
    [Arguments]    ${token}
    ${response}=    POST    /dev/stubs/confirm_payment    json='{"paymentToken": ${token}}'
    Status Should Be    200    ${response}