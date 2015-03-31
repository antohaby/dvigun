# Dvigun
## Что это?

Dvigun -- это обучаемый бот для онлайн-игры камень-ножницы-бумага  http://dvigun.by

## Как работает?

Код написан на Perl. 
Принцип работы прост:
1. Логинимся
2. Получаем guid
3. Запускаем поиск игры и получаем соперника.
4. Решаем что выбрать: камень, ножницы или бумагу. И ждем что выберет соперник.
5. Получаем 3 возможных исхода: проигрыш, ничья, выигрыш.
6. Возвращаемся к пункту 4 и продолжаем до тех пор пока сервер не скажет gameover
7. ???????
8. PROFIT!

## Как обучается?

Честно, в механизмах обучения различных нейронных сетей я шарю практически никак. ( Хотя данная тема мне интерестна  ;) ). 
Однако для этого случая я решил применить стохастическое дерево и наполнять его данными по мере разгадывания.
Теперь чуть подробнее. Я предположил что в игре КНБ с людьми существует некоторый общий человеческий фактор. 
Например после двух побед с бумагой против камня, человек решит сыграть за камень, т.к. подумает что противник выберет ножницы чтобы разрезать в клочья его победную бумагу, а на деле, ну вы поняли...
Т.е. есть некоторая стратегия которой придерживается тот или иной человек основывясь на предыдущих ходах.
Отсюда имеем постановку задачи: на основе истории ходов, предположить следующий ход противника.
Брать за основу полную историю ходов бессмысленно. Во-первых, обучение такой системы будет идти очень долго и нудно. Во-вторых шанс, что человек помнит и анализирует все свои ходы слишком мал 
да и у такого человека машина не выиграет. Поэтому берём короткий промежуток, скажем, последние 3 шага.
Какие данные нужно включить в историю? Сначала я думал включить 3 параметра: мой ход, ход противника, результат игры. 
Но потом понял что достаточно двух и оставил: ход противника и результат который он принес ему.
В итоге получается дерево глубиной 3 и ветвистостью 9(количество вариантов на количество возможных исходов). т.е. 9^3 элементов. 
Алгоритм работы с деревом такой:
1. Проходимся историей по дереву и находим конечный лист.
На листе есть 3 счетчика камень, ножницы, бумага. Смотрим что наиболее часто выбирает противник.
При этом преимущество должно быть явным. т.е. максимальный элемент должен быть на N процентов больше всех остальных, но я считаю не процентами, а фиксированным числом. например 5.
Если у нас нет явного лидера либо лидеров несколько, то в случайном порядке выбираем одного и тем самым делаем предположение.
2. После того как сделали предположение находим контр-решение. т.е. если предположили, что противник выберет бумагу, то выбираем ножницы и т.д. и засылаем на сервер.
3. Получаем ответ. вне зависимости от того выиграл противник или нет увеличиваем счетчик в листе из шага 1 т.е. обучаем дерево
Собственно модуль Stochastic + Stochastic::Tree выполняют все эти функции.

## Это работает?

Как это ни странно, но я делал синтетические тесты где программа-оппонент слепо следовал простым правилами. 
Например выбирать по порядку 1 2 3 в итоге примерно через 20 шагов дерево поняло что да как и все последующие ходы побеждала.
Тоже самое и с принципом выбирай то, что выбрал противник. 
И даже замысловатые последовательности 1 2 3 3 2 1 2 2 1 -- на основе истории из 3-х шагов дерево решало хорошо и только на определённом шаге давало сбой т.к. глубины не хватало.

К сожалению, в реальности не всё так хорошо :) и запустив алгоритм на реальных данных понял, что против меня в основном играют такие же боты, ну или почти такие же.
И они почему-то выигрывают чаще. Хотя если использовать простейший рандом, то выигрывать начинаю я :)

Однако некоторую информацию я все же смог вычленить: вероятность выбора ножниц на первом шаге заметно выше остальных. 
Связанно это скорее всего из-за того, что ножницы расположены по центру игральной панели. 


## АПИ dvigun.by

    Round
    http://dvigun.by/server/common?combs=1&guid=5e308c1be68334ac46e9b93cb5f4f7f815fb68cc&cmd=round
    cmd=round&left=1&right=2&result=1
    cmd=gameover&left=3&right=1&result=1&game_result=1&rating=1403&points=85
    
    Login
    http://dvigun.by/server/common?guid=5e308c1be68334ac46e9b93cb5f4f7f815fb68cc&cmd=login
    cmd=login&name=WhoAmI&guid=5e308c1be68334ac46e9b93cb5f4f7f815fb68cc&skin=1%2C1%2C1%2C1%2C1%2C1&points=85&rating=1403
    
    Get Room
    http://dvigun.by/server/common?typegame=1&guid=5e308c1be68334ac46e9b93cb5f4f7f815fb68cc&cmd=getroom
    cmd=room&name=Jonny%0A&guid=55f3521930d83aeae4faa86efd01f0f39f19cbbc&skin=7%2C6%2C1%2C5%2C11%2C7&points=635&rating=38
    
    
    POST http://dvigun.by/action/login
    remember=0&dvLogin=antoha.by%40gmail.com&dvPass=pass&remember=1
    {"result":false,"title":"\u041e\u0431\u043d\u0430\u0440\u0443\u0436\u0435\u043d\u0430 \u043e\u0448\u0438\u0431\u043a\u0430","info":"E-mail \u0438\u043b\u0438 \u041f\u0430\u0440\u043e\u043b\u044c \u0432\u0432\u0435\u0434\u0435\u043d \u043d\u0435\u0432\u0435\u0440\u043d\u043e.<br\/><a href=\"modal\/login\" id=\"repeat-login\">\u0412\u0432\u0435\u0441\u0442\u0438 \u0437\u0430\u043d\u043e\u0432\u043e<\/a>.","message":"<h2 class=\"red\">\u041e\u0431\u043d\u0430\u0440\u0443\u0436\u0435\u043d\u0430 \u043e\u0448\u0438\u0431\u043a\u0430<\/h2><div>E-mail \u0438\u043b\u0438 \u041f\u0430\u0440\u043e\u043b\u044c \u0432\u0432\u0435\u0434\u0435\u043d \u043d\u0435\u0432\u0435\u0440\u043d\u043e.<br\/><a href=\"modal\/login\" id=\"repeat-login\">\u0412\u0432\u0435\u0441\u0442\u0438 \u0437\u0430\u043d\u043e\u0432\u043e<\/a>.<\/div>"}
    
    remember=0&dvLogin=antoha.by%40gmail.com&dvPass=SHcHTSaY&remember=1
    {"result":true,"title":"\u0422\u044b \u0430\u0432\u0442\u043e\u0440\u0438\u0437\u043e\u0432\u0430\u043d.<br\/> \u0416\u0435\u043b\u0430\u0435\u043c \u043f\u043e\u0431\u0435\u0434\u044b \u0432 \u0438\u0433\u0440\u0435!","info":false,"reload":true,"page":false,"message":"<h2 class=\"green\">\u0422\u044b \u0430\u0432\u0442\u043e\u0440\u0438\u0437\u043e\u0432\u0430\u043d.<br\/> \u0416\u0435\u043b\u0430\u0435\u043c \u043f\u043e\u0431\u0435\u0434\u044b \u0432 \u0438\u0433\u0440\u0435!<\/h2><div><\/div>"}
    
    
    Get Dvigun
    http://dvigun.by/action/get_dvigun
    {"user_name":"WhoAmI","user_guid":"5e308c1be68334ac46e9b93cb5f4f7f815fb68cc","user_id":"10929","user_mobile_confirm":"1","user_mobile":"+375291233232","team_id":"0","hash":0,"user_proccess":"100%"}
    
    
    Login1 -> Get Dvigun -> Login -> Get Room -> Round -> Login -> ...