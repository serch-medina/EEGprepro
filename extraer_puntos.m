function ptos_registro = extraer_puntos(fpath, nombre_sujeto, recortado)
    % Funcion que extrae el numero de muestras que conforman el registro de
    % la senhal EEG. Se le puede indicar si el registro fue recortado para
    % localizar el numero de puntos de tal registro procesado.
    % Recibe como argumentos la ruta del directorio donde estan los 
    % archivos,el nombre del sujeto a buscar y opcionalmente la bandera 
    % que indica si el registro fue o no cortado.
    % Devuelve el numero de puntos que tiene el registro.
    % Para hallar el numero de puntos utiliza expresiones regulares.

    arguments
        fpath (1,:) char;
        nombre_sujeto (1,:) char;
        recortado (1,1) logical = false;
    end

    texto = fileread(fpath); % Texto del archivo de registro
        
    if recortado % verifica si se requieren puntos de los sujetos cortados
        patron = ['\(recortado\)\s*',nombre_sujeto,':\s*\d+'];
    else
        patron = ['Muestras\s*en\s*el\s*archivo\s*',nombre_sujeto,':\s*\d+'];
    end

    cadena = regexp(texto,patron,"match"); 
    ptos_celda = regexp(cadena,'\d+$',"match"); % Aplica dos veces regex 
                                                % una para buscar la linea
                                                % del sujeto. Otra para
                                                % extraer el numero de
                                                % muestras.
    if ~isempty(cadena)
        ptos_registro = str2double(ptos_celda{1}{1});
    else
        error('Error: cadena vacía, no se pudo recuperar el numero de puntos. Revisar si existe el sujeto')
end