# Proyecto: Sistema de Chat Distribuido en Elixir

Proyecto de chat distribuido desarrollado en Elixir, basado en una arquitectura Cliente-Servidor. Permite la comunicación en tiempo real entre múltiples usuarios con soporte para salas, almacenamiento de conversaciones y seguridad básica.
Este sistema aprovecha la concurrencia que ofrece Elixir para garantizar escalabilidad y toletancia a los fallos.

# Autores

- Juliana Andrea Bustamante Niño
- Jaider Andrés Melo Rodríguez
- Alejandro (?

# Estructura del Proyecto
├── nodo_cliente/                  # Código fuente del cliente
├── nodo_servidor/                  # Código fuente del servidor
├── cookies/                  # Código fuente de las cookies
├── sala/                  # Código fuente de la sala
├── supervisor/                  # Código fuente del supervisor
├── usuario/                  # Código fuente del usuario
├── util/                  # Código fuente del util
├── docs/                    # Documentación técnica y manuales
├── tests/                   # Scripts y resultados de pruebas de carga
└── README.md                # Este documento

# Requisitos
- Elixir >= 1.14
- Earlang/OTP >= 25

# Comandos que dispone en el cliente

---------------------------------------------------
| Comando        | Descripción                    |
---------------------------------------------------
| /list          | Muestra usuarios conectados    |
| /join          | Unirse a una sala de chat      |
| /create        | Crear una nueva sala           |
| /history       | Consultar historial de mensajes|
| /exit          | Salir del chat                 |
---------------------------------------------------

# Seguridad
- Autenticación básica de usuarios.
- Cifrado opcional de mensajes en tránsito.

# Documentación
Consultar la carpeta de documentos para la documentación técnica y el manual de usuario.

# Créditos
Proyecto final de la asignatura *Programación III*
- Universidad del Quindío
- Facultad de Ingeniería