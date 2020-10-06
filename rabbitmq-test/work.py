#!/usr/bin/env python3.6
import multiprocessing
import threading
import pika
import os,sys,time,logging,random
class Worker:
    def __init__(self, username, password, host, vhost, queue_name):
        self.username = username
        self.password = password
        self.host = host
        self.vhost = vhost
        self.queue_name = queue_name
        self.connection = None
        self.channel = None

        logger = logging.getLogger("MQ_WORKER")
        logger.setLevel(logging.DEBUG)
        fh = logging.FileHandler("/var/log/mq_worker.log")
        fh.setLevel(logging.DEBUG)
        ch = logging.StreamHandler()
        ch.setLevel(logging.INFO)
        formatter = logging.Formatter("[%(asctime)s] [%(levelname)s] [%(process)d] %(message)s")
        ch.setFormatter(formatter)
        fh.setFormatter(formatter)
        logger.addHandler(ch)
        logger.addHandler(fh)

        self.logger = logger

    def conn(self):
        if self.connection and not self.connection.is_closed:
            self.connection.close()
        credentials = pika.PlainCredentials(self.username, self.password)
        is_closed = True
        while is_closed:
            try:
                self.connection = pika.BlockingConnection(pika.ConnectionParameters(self.host,5672,self.vhost,credentials,heartbeat=60))
                is_closed = False
            except:
                self.logger.error('[main] AMQP_Connection_Error')
                time.sleep(2)
        self.channel = self.connection.channel()
        self.channel.basic_qos(prefetch_count=1)
        self.channel.queue_declare(queue=self.queue_name, durable=True)
        self.channel.basic_consume(queue=self.queue_name, on_message_callback=self.task)
        self.logger.info('[Connect Successfully] Waiting for messages. To exit press CTRL+C')
        self.channel.start_consuming()

    def heart(self):
        while True:
            time.sleep(20)
            try:
                self.connection.process_data_events()
                self.logger.debug(f'[heartbeat] Heartbeat check succeeded')
            except Exception as err:
                self.logger.error(f'[heartbeat] {err}')
                t = threading.Thread(target=self.conn)
                t.daemon = True
                t.start()
                k = True
                while k:
                    if self.connection.is_open:
                        k = False

    def task(self, ch, method, properties, body):
        num = random.uniform(0,1)
        self.logger.info(f'Received: {body},{num}')
        time.sleep(num)
        self.logger.info(f'Done: {body}')
        ch.basic_ack(delivery_tag=method.delivery_tag)
        self.logger.info(f'ACK: {body}')

#    def doit(self)
#        t = threading.Thread(target=self.task, args=(ch, method, properties, body,))
#        t.daemon = True
#        t.start()

    def main(self):
        t = threading.Thread(target=self.conn)
        t.daemon = True
        t.start()
        while True:
            if self.connection and not self.connection.is_closed:
                self.heart()

if __name__ == '__main__':
    w = Worker('admin','app','192.168.200.201','test','deploy')
    for i in range(400):
        p = multiprocessing.Process(target=w.main)
        p.start()
