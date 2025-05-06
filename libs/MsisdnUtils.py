"""
A few utils for working with msisdn format
"""
import random

class MsisdnUtils(object):
    """
    A few utils for working with msisdn format
    """
    def generate_random_msisdn():
        return str(random.randint(71111111111, 79999999999))
    
    def generate_random_fullname():
        female_names = ['Анна', 'Ангелина', 'Анастасия', 'Александра', 'Алиса', 'Василиса', 'Ольга', 'Евгения', 'Мария', 'Екатерина']
        male_names = ['Аркадий', 'Анатолий', 'Павел', 'Александр', 'Михаил', 'Игорь', 'Олег', 'Евгений', 'Марк', 'Валерий']
        fathers_names = ['Владимиров', 'Аркадьев', 'Александров', 'Олегов', 'Алексеев', 'Михайлов', 'Андреев', 'Яковлев']
        surnames = ['Иванов', 'Петров', 'Сидоров', 'Васнецов', 'Леонтьев', 'Семенов', 'Соколов', 'Смирнов', 'Кузнецов', 'Лебедев', 'Козлов']
        if random.randint(0, 1):
            full_name = random.choice(female_names) + " " + random.choice(fathers_names) + "на " + random.choice(surnames) + "а"
        else:
            full_name = random.choice(male_names) + " " + random.choice(fathers_names) + "ич " + random.choice(surnames)
        return full_name