defmodule Cliente do
  def inicio(pid_servidor) do
    IO.puts("Estás registrado en el servidor? (s/n): ")
    registrado? = IO.gets("") |> String.trim()

    IO.write("Tu nombre de usuario es: ")
    nombre_usuario = IO.gets("") |> String.trim()

    IO.write("Tu contraseña es: ")
    contrasena = IO.gets("") |> String.trim()

    case registrado? do
      "s" ->
        if Autenticarse.autenticacion(nombre_usuario, contrasena) do
          send(pid_servidor, {:conectar, self(), nombre_usuario})
          escuchar(pid_servidor, nombre_usuario)
        else
          IO.puts("Error: Usuario o contraseña incorrectos.")
        end

      "n" ->
        case Autenticarse.registrar(nombre_usuario, contrasena) do
          {:ok, :registrado} ->
            IO.puts("Usuario registrado correctamente.")
            send(pid_servidor, {:conectar, self(), nombre_usuario})
            escuchar(pid_servidor, nombre_usuario)

          {:error, :usuario_existente} ->
            IO.puts("Error: El usuario ya existe.")
          end

      _ ->
        IO.puts("Opción no válida. Por favor, introduce 's' o 'n'.")
    end
  end

  defp escuchar(pid_servidor, nombre_usuario) do
    spawn(fn ->
      salida_ciclo(pid_servidor) end)
    ciclo(pid_servidor, nombre_usuario)
  end

  defp salida_ciclo(pid_servidor) do
    for linea <- IO.stream(:stdio, :linea), do: Cliente.manejo_salida(pid_servidor, String.trim(linea))
  end

  def manejo_salida(pid_servidor, "/list"), do: send(pid_servidor, {:listar_usuarios, self()})
  def manejo_salida(pid_servidor, "/history"), do: send(pid_servidor, {:historial, self()})
  def manejo_salida(pid_servidor, "/exit"), do: send(pid_servidor, {:desconectar, self()})
  def manejo_salida(pid_servidor, <<"/create", sala::binary>>), do: send(pid_servidor, {:crear_sala, self(), sala})
  def manejo_salida(pid_servidor, <<"/join", sala::binary>>), do: send(pid_servidor, {:unirse_sala, self(), sala})
  def manejo_salida(pid_servidor, mensaje), do: send(pid_servidor, {mensaje, self(), mensaje})

  defp ciclo(pid_servidor, nombre_usuario) do
    receive do
      {:Bienvenido, _} -> IO.puts("Bienvenido #{nombre_usuario}"); ciclo(pid_servidor, nombre_usuario)
      {:mensaje, de, mensaje} -> IO.puts("#{de}: #{mensaje}"); ciclo(pid_servidor, nombre_usuario)
      {:sala_creada, sala} -> IO.puts("Sala #{sala} creada."); ciclo(pid_servidor, nombre_usuario)
      {:unido_sala, sala} -> IO.puts("Te has unido a la sala #{sala}"); ciclo(pid_servidor, nombre_usuario)
      {:usuarios, lista} -> IO.puts("Usuarios: #{Enum.join(lista, ", ")}"); ciclo(pid_servidor, nombre_usuario)
      {:historial, contenido} -> IO.puts("Historial: \n#{contenido}"); ciclo(pid_servidor, nombre_usuario)
      {:error, mensaje} -> IO.puts("Error: #{mensaje}"); ciclo(pid_servidor, nombre_usuario)
    end
  end
end
