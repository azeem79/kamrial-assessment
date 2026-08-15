import os
import sys
import pika

RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
QUEUE_NAME = "task_queue"

def send_jobs(count=5):
    connection = pika.BlockingConnection(pika.ConnectionParameters(host=RABBITMQ_HOST))
    channel = connection.channel()
    channel.queue_declare(queue=QUEUE_NAME, durable=True)

    for i in range(count):
        message = f"Test Job {i+1}"
        channel.basic_publish(
            exchange='',
            routing_key=QUEUE_NAME,
            body=message,
            properties=pika.BasicProperties(delivery_mode=2)  # Make message persistent
        )
        print(f" [x] Sent '{message}'")

    connection.close()

if __name__ == "__main__":
    num_jobs = int(sys.argv[1]) if len(sys.argv) > 1 else 5
    send_jobs(num_jobs)