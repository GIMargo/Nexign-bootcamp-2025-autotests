*** Settings ***
Documentation   API Testing manager role
Library    RequestsLibrary
Library    Collections
Library    MsisdnUtils

*** Variables ***
${host}             http://localhost:8000
${manager_login}    vasily-ivanych
${manager_password}  right-password

*** Test Cases ***
Manager Valid Auth
    [Documentation]    Авторизация менеджера с валидными логином и паролем
    ${response}=    Try Authenticate with    ${manager_login}    ${manager_password}
    Status Should Be    200    ${response}
    Dictionary Should Contain Key    ${response.headers}    accessToken

Pay the balance by manager
    [Documentation]    Пополнение баланса абонента менеджером
    Authenticate as manager    
    ${msisdn}=    Get random Romashka msisdn
    ${balance_before}=    Get subscriber balance    ${msisdn}
    ${response}=    POST On Session    manager_session    /api/v1/manager/subscribers/${msisdn}/pay     json='{"amount": 0.1}'
    Status Should Be    200    ${response}
    ${balance_after}=    Get subscriber balance    ${msisdn}
    ${expected_balance}=    Evaluate    ${balance_before}+${0.1}
    Should Be Equal As Numbers    ${balance_after}    ${expected_balance}

Change Tariff from Classika to Pomesyachny
    [Documentation]    Изменение тарифа абонента с "Классики" на "Помесячный"
    Authenticate as manager
    ${msisdn}=    Get random Classica tariff msisdn
    ${tariff_before}=    Get subscriber tariff    ${msisdn}
    ${balance_before}=    Get subscriber balance    ${msisdn}
    Should Be Equal As Numbers    ${tariff_before}    11
    ${response}=    PUT On Session    manager_session    /api/v1/manager/subscribers/${msisdn}    json='{"tariff_id": 12}'
    Status Should Be    200    ${response}
    ${tariff_after}=    Get subscriber tariff    ${msisdn}
    Should Be Equal As Numbers    ${tariff_after}    12
    ${balance_after}=    Get subscriber balance    ${msisdn}
    ${expected_balance}=    Evaluate    ${balance_before}-${100}
    Should Be Equal As Numbers    ${balance_after}    ${expected_balance}

Change Tariff from Pomesyachny to Classika
    [Documentation]    Изменение тарифа абонента с "Помесячного" на "Классику"
    Authenticate as manager
    ${msisdn}=    Get random Pomesyachny tariff msisdn
    ${tariff_before}=    Get subscriber tariff    ${msisdn}
    Should Be Equal As Numbers    ${tariff_before}    12
    ${response}=    PUT On Session    manager_session    /api/v1/manager/subscribers/${msisdn}    json='{"tariff_id": 11}'
    Status Should Be    200    ${response}
    ${tariff_after}=    Get subscriber tariff    ${msisdn}
    Should Be Equal As Numbers    ${tariff_after}    11

Create New Subscriber
    [Documentation]    Создание нового абонента менеджером
    Authenticate as manager
    ${msisdn}=    Get random NON Romashka msisdn
    ${name}=    Get random name
    ${response}=    POST On Session    manager_session    /api/v1/manager/subscribers/${msisdn}    json='{"full_name": ${name}}'
    Status Should Be    200    ${response}
    Check all subscribers creation params    ${msisdn}    ${name}

Get Subscriber information
    [Documentation]    Запрос информации об абоненте менеджером
    Authenticate as manager
    ${msisdn}=    Get random Romashka msisdn
    ${response}=    Get subscriber info    ${msisdn}
    Dictionary Should Contain Key    ${response.json()}    msisdn
    Dictionary Should Contain Key    ${response.json()}    full_name
    Dictionary Should Contain Key    ${response.json()}    balance
    Dictionary Should Contain Key    ${response.json()}    registration_date
    Dictionary Should Contain Key    ${response.json()}    tariff_id

Get Subscribers List
    [Documentation]    Получение списка абонентов менеджером
    Authenticate as manager
    ${response}=    GET On Session    manager_session    /api/v1/manager/subscribers
    Status Should Be    200    ${response}
    ${subscriber}=  Evaluate  random.choice(${response.json()})  random
    Dictionary Should Contain Key    ${subscriber}    msisdn
    Dictionary Should Contain Key    ${subscriber}    full_name
    Dictionary Should Contain Key    ${subscriber}    balance
    Dictionary Should Contain Key    ${subscriber}    registration_date
    Dictionary Should Contain Key    ${subscriber}    tariff_id

*** Keywords ***

Try Authenticate with 
    [Documentation]    Аутентификация и авторизация с переданными логином и паролем
    [Arguments]    ${login}    ${password}
    ${response}=    POST  ${host}/api/v1/manager/auth    json='{"login": "${login}", "password": "${password}"}'
    RETURN ${response}

Authenticate as manager
    [Documentation]    Аутентификация и авторизация под ролью "менеджер" и создание сессии
    ${response}=    Try Authenticate with     ${manager_login}    ${manager_password}
    Status Should Be    200    ${response}
    Create Session    manager_session    ${host}    headers=${response.headers}

Get random Romashka msisdn
    [Documentation]    Выбор случайного абонента "Ромашки"
    ${response}=    GET On Session    manager_session    /api/v1/manager/subscribers
    Status Should Be    200    ${response}
    ${subscriber}=  Evaluate  random.choice(${response.json()})  random
    ${msisdn}=    Get From Dictionary    ${subscriber}   msisdn
    RETURN ${msisdn}

Get random NON Romashka msisdn
    [Documentation]    Выбор случайного абонента НЕ "Ромашки"
    ${msisdn}=    Generate Random Msisdn
    ${response}=    GET On Session    manager_session    /api/v1/manager/subscribers/${msisdn}
    WHILE    ${response.Status} != 404
        ${msisdn}=    Generate Random Msisdn
        ${response}=    GET On Session    manager_session    /api/v1/manager/subscribers/${msisdn}
    END
    RETURN ${msisdn}

Get random Classica tariff msisdn
    [Documentation]    Выбор случайного абонента "Ромашки" с тарифом "Классика" (он обязательно должен быть)
    ${msisdn}=    Get random Romashka msisdn
    ${tariff}=    Get subscriber tariff    ${msisdn}
    WHILE    ${tariff} != 11
        ${msisdn}=    Get random Romashka msisdn
        ${tariff}=    Get subscriber tariff    ${msisdn}
    END
    RETURN ${msisdn}

Get random Pomesyachny tariff msisdn
    [Documentation]    Выбор случайного абонента "Ромашки" с тарифом "Помесячный" (он обязательно должен быть)
    ${msisdn}=    Get random Romashka msisdn
    ${tariff}=    Get subscriber tariff    ${msisdn}
    WHILE    ${tariff} != 12
        ${msisdn}=    Get random Romashka msisdn
        ${tariff}=    Get subscriber tariff    ${msisdn}
    END 
    RETURN ${msisdn}

Get random name
    [Documentation]    Генерация случайных ФИО
    ${name}=    Generate Random Fullname  
    RETURN ${name}

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

Get subscriber tariff
    [Documentation]    Получение тарифа выбранного абонента
    [Arguments]    ${msisdn}
    ${json}=    Get subscriber info    ${msisdn}
    ${tariff}=    Get From Dictionary    ${json}    tariff_id
    RETURN ${tariff}

Check all subscribers creation params
    [Documentation]    Проверка корректности всех полей абонента после его создания
    [Arguments]    ${msisdn}    ${name}
    ${json}=    Get subscriber info    ${msisdn}
    ${tariff}=    Get From Dictionary    ${json}    tariff_id
    ${balance}=    Get From Dictionary    ${json}    balance
    ${full_name}=    Get From Dictionary    ${json}    full_name
    Should Be Equal As Numbers   ${tariff}    11 
    Should Be Equal As Numbers   ${balance}    100
    Should Be Equal As Strings    ${full_name}    ${name}