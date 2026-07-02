from plot_and_filter import *
from pathlib import Path
def extraer_datos(recortar = False, forzar_procesamiento = False):
    """Funcion que exporta los datos de actividad y eventos filtrados y corregido. Guarda en un registro su actividad
    recortar : booleano
        Cuando se encuentra activo recorta los espacios entre medio de los eventos que hayan sido descartados
    forzar : booleano
        Cuando se encuentra activo fuerza a reprocesar todos los archivos que encuentre en los directorios indicados
    """

    # Crea los directorios por primera vez. Las funciones que exportan tambien intentan realizar esta accion
    ruta_filtrados = Path(r'.\datos_exportados_py\actividad_filtrada')
    ruta_modificados = Path(r'.\datos_exportados_py\eventos_modificados')
    if not ruta_filtrados.is_dir() or not ruta_modificados.is_dir():
        os.makedirs(ruta_filtrados)
        os.makedirs(ruta_modificados)

    src_dir = Path(r'.\datos_exportados_m\eventos_exportados') # Carpeta desde donde se cargan los archivos de eventos
    print(f'Leyendo archivos de la carpeta: {src_dir}\n')
    files = sorted(src_dir.glob('*.txt')) # Carga todos los archivos de texto en la carpeta, ordenados alfabéticamente
    print(f'Número de archivos encontrados: {len(files)}\n')
    print(f'Mostrando archivos: {files}')

    os.makedirs(r'.\registros', exist_ok=True) # Crea la carpeta de registros si no existe
    path_archivo_registro = Path(r'.\registros\registro_preprocesamiento.txt') # Archivo de registro de procesamiento
    archivo_registro = open(path_archivo_registro, 'a', encoding='utf-8') # Abre el archivo de registro en modo append para agregar información al final
    print("--------------------------------------------- INGRESANDO NUEVO REGISTRO ---------------------------------------------", file=archivo_registro)

    # ! Se configura la salida de los comandos print para que se escriba automaticamente en el archivo de registro

    for file in files:
        sbjct_name_mod = file.stem # Obtiene el nombre del sujeto sin la extensión
        sbjct_name = sbjct_name_mod.replace("_eventos","") # Extrae el nombre del sujeto del experimento

        archivo_exportado = Path(r'.\datos_exportados_py\actividad_filtrada') / f'{sbjct_name}_actividad_filtrada' # Ruta del archivo que se guardará
        archivo_exportado_rec = Path(r'.\datos_exportados_py\actividad_filtrada') / f'{sbjct_name}_actividad_filtrada_rec'

        print(f'\nArchivo de actividad a exportar: {f"{sbjct_name}_actividad_filtrada"}',file=archivo_registro) # Escribe en el archivo de registro el nombre del archivo que se va a exportar
        
        """ 
        ! Verifica si el archivo de actividad existe, en cuyo caso ejecuta el resto de codigo, 
        ! pero si el archivo ya existe, salta al siguiente sujeto 
        """
        if not forzar_procesamiento:
            if archivo_exportado.is_file():
                print(f'Archivo de actividad ya existe. Saltando el procesamiento de {file.name}.')
                continue
            elif archivo_exportado_rec.is_file():
                print(f'Archivo de actividad ya existe. Saltando el procesamiento de {file.name}.')
                continue

        print(f'Procesando el sujeto: {sbjct_name} \n',file=archivo_registro)
        # cargamos los eventos del sujeto para procesarlos
        Hsub_eventos = carga_archivo_eventos(file.name)
        print(f'Número de eventos cargados para {sbjct_name}: {len(Hsub_eventos)}',file=archivo_registro)
        print(Hsub_eventos.head(n=15),file=archivo_registro)
        # filtramos los eventos y los guardamos; registramos numero de ensayos hallados
        num_ensayos, Hsub_eventos_modificados  = modificar_eventos(Hsub_eventos, path_archivo_registro)
        print(f'Número de ensayos procesados para {sbjct_name}: {num_ensayos} \n', file=archivo_registro)

        # Para verificar que las duraciones sean correctas, guarda el registro en un archivo de texto
        verif_duraciones(Hsub_eventos_modificados)

        # cargamos datos de actividad y tiempo del sujeto para procesarlos
        Hsub_tiempo, Hsub_actividad = carga_archivo_acttiem(f'time_vector_corrected_{sbjct_name}.csv', f'{sbjct_name}_actividad.txt')
        # guardamos numero de muestras y cabecera del archivo de actividad en el registro
        print(f'Número de muestras en Hsub_actividad para {sbjct_name}: {Hsub_actividad.shape[0]} \n', file=archivo_registro)
        print(Hsub_actividad.head(n=15), file=archivo_registro)
        
        # aplicamos el filtro
        Hsub_filtrada = filtrado_butterworth(Hsub_actividad)
        if recortar:
            # # cortamos los datos de los ensayos que hayan sido eliminados, ajustamos duracion de eventos
            actividad_cortada, eventos_cortados = cortar_tiempo_entre_ensayos(Hsub_eventos_modificados, Hsub_filtrada)
            # exportamos los datos
            exportar_eventos(eventos_cortados, f'{sbjct_name}_eventos_modificados_rec') # el archivo que guardará y el nombre del sujeto,
            exportar_actividad(actividad_cortada, f'{sbjct_name}_actividad_filtrada_rec') # el archivo que guardará y el nombre del sujeto, 
                                                                        # sin extensión ni carpeta, solo el nombre del archivo.
                                                                        #  Se guardará en la carpeta 'filtrados'.
        else:
            exportar_eventos(Hsub_eventos_modificados, f'{sbjct_name}_eventos_modificados') # el archivo que guardará y el nombre del sujeto,
            exportar_actividad(Hsub_filtrada, f'{sbjct_name}_actividad_filtrada')

        # Graficamos datos antes y después del filtrado. Además de la actividad referenciada al promedio de todos los canales
        graficar_datos(sbjct_name, Hsub_tiempo, Hsub_actividad, 'T8', 'antes', 'T8')
        # * No hay realmente un cambio apreciable en la actividad referencia al promedio y la actividad habitual
        # Hsub_actividad_wdof = Hsub_actividad - Hsub_actividad.mean(axis=0) 
        # graficar_datos(sbjct_name, Hsub_tiempo, Hsub_actividad_wdof, 'T8', 'antes', 'T8_wdof')
        # ! La funcion no esta bien preparada para manejar diferentes tipos de datos. H_sub_filtrada es tipo numpy
        # ! mientras que Hsub_actividad es tipo data frame, en una se debe usar numero y en otra enteros.
        # ! Hay que revisar que nombres de electrodos corresponden a cada numero
        graficar_datos(sbjct_name, Hsub_tiempo, Hsub_filtrada, 18, 'despues', 'T8')
        graficar_comparacion(sbjct_name, Hsub_tiempo, Hsub_actividad, Hsub_filtrada, 18, 'T8')

    archivo_registro.close()