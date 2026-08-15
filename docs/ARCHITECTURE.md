# Platform Architecture

```text
                  +-----------------------+
                  |    Public Internet    |
                  +-----------------------+
                              |
                              v
                  +-----------------------+
                  |   ALB / API Service   |
                  |   (Public Subnet)     |
                  +-----------------------+
                     /                 \
                    /                   \
                   v                     v
+-----------------------+       +-----------------------+
|  RabbitMQ Message Q   |       | PostgreSQL Database   |
|   (Private Subnet)    |       |   (Private Subnet)    |
+-----------------------+       +-----------------------+
                   \
                    v
          +-----------------------+
          |   Background Worker   |
          |   (Private Subnet)    |
          +-----------------------+