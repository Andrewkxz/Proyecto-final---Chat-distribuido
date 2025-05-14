@moduledoc """
  Modulo Usuario que maneja la autenticación y registro de usuarios.
  """
defmodule Usuario do
  # Define la estructura del usuario con los campos nombre, pid y contrasena.
  # El campo nombre es una cadena de texto, pid es el identificador del proceso y contrasena es la contraseña del usuario.
  defstruct nombre: "", pid: nil, contrasena: nil

  # Define el nombre del archivo donde se almacenan los usuarios.
  # El archivo se llama "usuarios.txt" y se encuentra en el directorio actual.
  @usuarios "usuarios.txt"

  # Función principal que inicia el proceso de autenticación.
  def autenticar() do
    # Se solicita el nombre de usuario y la contraseña al usuario.
    nombre = Util.ingresar("Ingrese su nombre: ", :texto)
    contrasena = Util.ingresar("Contraseña: ", :texto)

    # Se verifica si el nombre de usuario y la contraseña son válidos.
    case buscar_usuario(nombre) do
      {:ok, contrasena_guardada} ->
        # Si el nombre de usuario ya existe, se verifica la contraseña.
        if contrasena_guardada == contrasena do
          # Si la contraseña es correcta, se muestra un mensaje de autenticación exitosa.
          Util.mostrar_mensaje("Autenticación exitosa")
          # Se espera 500 ms para evitar la saturación de mensajes.
          :timer.sleep(500)
          #Se crea un nuevo usuario con el nombre y el pid del proceso actual.
          # Se utiliza self() para obtener el pid del proceso actual.
          %Usuario{nombre: nombre, pid: self()}
        else
          # Si la contraseña es incorrecta, se muestra un mensaje de error.
          Util.mostrar_mensaje("Contraseña incorrecta")
          # Se llama a la función autenticar() para volver a solicitar el nombre de usuario y la contraseña.
          # Se utiliza la recursión para volver a llamar a la función autenticar().
          autenticar()
        end

      :error ->
        # Si el nombre de usuario no existe, se solicita al usuario que lo registre.
        Util.mostrar_mensaje("Registrando usuario...")
        # Se solicita el nombre de usuario y la contraseña al usuario.
        registrar_usuario(nombre, contrasena)
        # Se crea un nuevo usuario con el nombre y el pid del proceso actual.
        %Usuario{nombre: nombre, pid: self()}
      end
    end

  # Función privada que busca un usuario en el archivo de usuarios.
    defp buscar_usuario(nombre) do
      # Se utiliza File.exists? para verificar si el archivo de usuarios existe.
      if File.exists?(@usuarios) do
        # Si el archivo existe, se utiliza File.stream! para leer el archivo línea por línea.
        File.stream!(@usuarios)
        # Se utiliza Enum.find_value para buscar el nombre de usuario en el archivo.
        |> Enum.find_value(:error, fn linea ->
          # Se utiliza String.split para dividir la línea en nombre y contraseña.
          case String.split(String.trim(linea), ":") do
            # Si la línea contiene un nombre y una contraseña, se verifica si el nombre coincide.
            [nombre_guardado, contrasena_guardada] when nombre_guardado == nombre ->
              # Si el nombre coincide, se devuelve la contraseña guardada.
              {:ok, contrasena_guardada}
            # Si la línea no contiene un nombre y una contraseña, se devuelve nil.
            # Se utiliza el operador _ para ignorar el resto de la línea.
            _ -> nil
          end
        end)
      else
        # Si el archivo no existe, se devuelve :error.
        # Se utiliza el operador :error para indicar que no se encontró el usuario.
        :error
    end
  end

  # Función privada que registra un nuevo usuario en el archivo de usuarios.
  defp registrar_usuario(nombre, contrasena) do
    # Se escribe el nuevo usuario en el archivo de usuarios.
    # Se utiliza File.write! para escribir el nombre y la contraseña en el archivo.
    # Se utiliza [:append] para agregar el nuevo usuario al final del archivo sin sobrescribirlo.
    File.write!(@usuarios, "#{nombre}:#{contrasena}\n", [:append])
    # Se imprime un mensaje de registro exitoso en la consola.
    Util.mostrar_mensaje("Usuario registrado con éxito")
  end

  # Función privada que carga los usuarios desde el archivo de usuarios.
  def cargar_usuarios() do
    # Se utiliza File.exists? para verificar si el archivo de usuarios existe.
    if File.exists?(@usuarios) do
      # Si el archivo existe, se utiliza File.stream! para leer el archivo línea por línea.
      File.stream!(@usuarios)
      # Se utiliza Enum.reduce para acumular los usuarios en un mapa.
      |> Enum.reduce(%{}, fn linea, acc ->
        # Se utiliza String.split para dividir la línea en nombre y contraseña.
        case String.split(String.trim(linea), ":") do
          # Si la línea contiene un nombre y una contraseña, se agrega al mapa de usuarios.
          # Se utiliza el operador %Usuario{} para crear un nuevo usuario con el nombre y la contraseña.
          [nombre, contrasena] -> Map.put(acc, nombre, %Usuario{nombre: nombre, pid: nil, contrasena: contrasena})
          # Si la línea no contiene un nombre y una contraseña, se ignora.
          # Se utiliza el operador _ para ignorar el resto de la línea.
          _ -> acc
        end
      end)
    else
      # Si el archivo no existe, se devuelve un mapa vacío.
      # Se utiliza el operador %{} para crear un mapa vacío.
      %{}
    end
  end
end
