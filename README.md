# О репозитории

В данном репозитории представлены автотесты, написанные в рамках курса по тестированию Nexign bootcamp 2025.

В репозитории представлены:
* Автотесты для валидации CDR-файла с записями о звонках абонента
* Автотесты API компонента (высокоприоритетные тесты)
* Автотесты на e2e сценарии эмуляции звонка и тарификации (несколько высокоприоритетных тестов)

Для написания автотестов использовались: Robot Framework, Python. 

# Навигация

* В папке test_data хранятся данные, необходимые для запуска тестов
* В папке libs хранятся вспомогательные библиотеки (AMQPMsg взята отсюда: https://github.com/ctradu/robotframework-amqp)
* BRT_tests.robot -- тесты валидации CDR сервисом BRT 
* API_manager_tests.robot -- тесты API с ролью менеджера
* API_subscriber_tests.robot -- тесты API с ролью абонента
* End-to-End_tests.robot -- тесты на e2e сценарии эмуляции звонка и тарификации

# Запуск тестов

Запуск тестов:

```sh
robot --pythonpath libs BRT_tests.robot 
```
```sh
robot --pythonpath libs API_manager_tests.robot 
```
```sh
robot --pythonpath libs API_subscriber_tests.robot 
```
```sh
robot --pythonpath libs End-to-End_tests.robot 
```