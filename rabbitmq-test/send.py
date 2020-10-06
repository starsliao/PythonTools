#!/usr/bin/env python3.6
import pika
import sys,datetime,time
import multiprocessing,logging

logger = logging.getLogger("MQ_SENDER")
logger.setLevel(logging.DEBUG)
fh = logging.FileHandler("/var/log/mq_sender.log")
fh.setLevel(logging.DEBUG)
#ch = logging.StreamHandler()
#ch.setLevel(logging.INFO)
formatter = logging.Formatter("[%(asctime)s] [%(levelname)s] [%(process)d] %(message)s")
#ch.setFormatter(formatter)
fh.setFormatter(formatter)
#logger.addHandler(ch)
logger.addHandler(fh)

def sender():
    credentials = pika.PlainCredentials('admin','app')
    connection = pika.BlockingConnection(pika.ConnectionParameters('192.168.200.201',5672,'test',credentials))
    channel = connection.channel()
    channel.queue_declare(queue='deploy', durable=True)
    try:
        for i in range(1,100001):
            #message = datetime.datetime.now().strftime('%Y_%m_%d_%H:%M:%S.%f')
            channel.basic_publish(exchange='',routing_key='deploy',body=str(i),properties=pika.BasicProperties(delivery_mode=2))
            logger.info(f'[sender]{i}')
            time.sleep(1)
        connection.close()
    except KeyboardInterrupt:
        connection.close()
        print('EXIT!')
for i in range(600):
    p = multiprocessing.Process(target=sender)
    p.start()
