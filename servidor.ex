defmodule Servidor do
  def inicio do
    spawn(__MODULE__, :init, [%{usuarios: %{}, salas: %{}}])
  end

  def init(estado), do: ciclo(estado)

  defp ciclo(estado) do
    receive do
      {:conectar, pid, nombre_usuario} ->
        send(pid, {:Bienvenido, nombre_usuario})
        ciclo(%{estado | usuarios: Map.put(estado.usuarios, pid, %{nombre: nombre_usuario, sala: nil})})

      {:desconectar, pid} ->
        loop(%{estado | usuarios: Map.delete(estado.usuarios, pid)})

      {:crear_sala, pid, nombre_sala} ->
        if.Map.has_key?(estado.salas, nombre_sala) do
          send(pid, {:error, "La sala ya existe."})
        else
          send(pid, {:sala_creada, nombre_sala})
          ciclo(%{estado | salas: Map.put(estado.salas, nombre_sala, [])})
        end

      {:unirse_sala, pid, nombre_sala} ->
        if Map.has_key?(estado.salas, nombre_sala) do
          actualizar_salas = Map.update!(estado.salas, nombre_sala, fn usuarios -> [pid | usuarios] end)
          actualizar_usuarios = Map.update!(estado.usuarios, pid, &Map.put(&1, :sala, nombre_sala))
          send(pid, {:unido_sala, nombre_sala})
          ciclo(%{estado | salas: actualizar_salas, usuarios: actualizar_usuarios})
        else
          send(pid, {:error, "Sala no encontrada."})
          ciclo(estado)
        end

      {:mensaje, pid, texto} ->
        usuario = Map.get(estado.usuarios, pid)
        if usuario && usuario.sala do
          Enum.each(estado.salas[usuario.sala], fn x -> send(x, {:mensaje, usuario.nombre, texto}) end)
        else
          send(pid, {:error, "No estás en ninguna sala."})
        end
        ciclo(estado)

      {:listar_usuarios, pid} ->
        nombre_usuarios = Enum.map(estado.usuarios, fn {_pid, usr} -> usr.nombre end)
        send(pid, {:usuarios, nombre_usuarios})
        ciclo(estado)

      {:historial, pid} ->
        usuario = Map.get(estado.usuarios, pid)
        if usuario && usuario.sala do
          send(pid, {:historial, Util.cargar_historial(usuario.sala)})
        end
        ciclo(estado)
      end
    end
  end
