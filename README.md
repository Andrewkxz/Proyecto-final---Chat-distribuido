# Proyecto: Sistema de Chat Distribuido en Elixir

Proyecto de chat distribuido desarrollado en Elixir, basado en una arquitectura Cliente-Servidor.  
Permite la comunicación en tiempo real entre múltiples usuarios con soporte para salas, almacenamiento de conversaciones y seguridad básica.  
Este sistema aprovecha la concurrencia que ofrece Elixir para garantizar escalabilidad y tolerancia a fallos.

## Autores

- Juliana Andrea Bustamante Niño  
- Jaider Andrés Melo Rodríguez  
- Jhenier Alejandro Araujo Madroñero  

## Estructura del Proyecto

```plaintext
nodo_cliente.exs     # Código fuente del cliente
nodo_servidor.exs    # Código fuente del servidor
cookie.exs           # Código fuente de las cookies
sala.ex              # Código fuente de la sala
supervisor.exs       # Código fuente del supervisor
usuario.ex           # Código fuente del usuario
util.ex              # Código fuente de utilidades
docs/                # Documentación técnica y manuales
README.md            # Este documento
```

## Requisitos

- Elixir >= 1.14  
- Erlang/OTP >= 25  

## Comandos que dispone el usuario fuera de una sala

| Comando                       | Descripción                          |
|-------------------------------|--------------------------------------|
| `/create <nombre de la sala>` | Crea una nueva sala de chat.         |
| `/join <nombre de la sala>`   | Unirse a una sala de chat existente. |
| `/list`                       | Ver lista de usuarios conectados.    |
| `/help`                       | Muestra este menú.                   |
| `/close`                      | Cierra sesión.                       |


## Comandos que dispone el usuario dentro de una sala

| Comando          | Descripción                                        |
|------------------|----------------------------------------------------|
| `/msg <mensaje>` | Envía un mensaje a la sala.                        |
| `/history`       | Consultar historial de mensajes de la sala actual. |
| `/search`        | Busca mensajes por palabra clave en el historial.  |
| `/exit`          | Salir de la sala actual.                           |
| `/help`          | Muestra este menú.                                 |
| `/close`         | Cierra sesión.                                     |

## Seguridad

- Autenticación básica de usuarios.  
- Cifrado de mensajes en tránsito.  

## Documentación

Consultar la carpeta `docs/` para la documentación técnica y el manual de usuario.

## Créditos

Proyecto final de la asignatura **Programación III**  
Universidad del Quindío - Facultad de Ingeniería
