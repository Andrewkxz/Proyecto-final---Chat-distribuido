# Proyecto: Sistema de Chat Distribuido en Elixir

Proyecto de chat distribuido desarrollado en Elixir, basado en una arquitectura Cliente-Servidor.  
Permite la comunicación en tiempo real entre múltiples usuarios con soporte para salas, almacenamiento de conversaciones y seguridad básica.  
Este sistema aprovecha la concurrencia que ofrece Elixir para garantizar escalabilidad y tolerancia a fallos.

## Autores

- Juliana Andrea Bustamante Niño  
- Jaider Andrés Melo Rodríguez  
- Alejandro Araujo  

## Estructura del Proyecto

```plaintext
nodo_cliente.exs     # Código fuente del cliente
nodo_servidor.exs    # Código fuente del servidor
cookies.exs          # Código fuente de las cookies
sala.ex              # Código fuente de la sala
supervisor.exs       # Código fuente del supervisor
usuario.ex           # Código fuente del usuario
util.ex              # Código fuente de utilidades
docs/                # Documentación técnica y manuales
tests/               # Scripts y resultados de pruebas de carga
README.md            # Este documento
```

## Requisitos

- Elixir >= 1.14  
- Erlang/OTP >= 25  

## Comandos que dispone en el cliente

| Comando   | Descripción                         |
|-----------|-------------------------------------|
| `/list`   | Muestra usuarios conectados         |
| `/join`   | Unirse a una sala de chat           |
| `/create` | Crear una nueva sala                |
| `/history`| Consultar historial de mensajes     |
| `/exit`   | Salir del chat                      |

## Seguridad

- Autenticación básica de usuarios.  
- Cifrado opcional de mensajes en tránsito.  

## Documentación

Consultar la carpeta `docs/` para la documentación técnica y el manual de usuario.

## Créditos

Proyecto final de la asignatura **Programación III**  
Universidad del Quindío - Facultad de Ingeniería
