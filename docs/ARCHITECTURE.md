# Platform Architecture Diagram
+-------------------------------------------------+
            |                  Public Internet                |
            +-------------------------------------------------+
                                     |
                                     v
                     +-------------------------------+
                     |     API Service (Public)      |
                     +-------------------------------+
                              |             |
                              v             v
  +-------------------------------+     +-------------------------------+
  |   PostgreSQL DB (Private)     |     |   Background Worker (Private) |
  +-------------------------------+     +-------------------------------+
  ### Architecture Highlights
- **Public API:** Entry point for client requests.
- **Private PostgreSQL & Worker:** Isolated from public internet access.
- **State & Queue Management:** Worker processes background jobs asynchronously from the API.