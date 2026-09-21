import re # importado de modulo para busqueda por expresiones regulares
import csv
import os
import pandas as pd
from plot_and_filter import *
from pathlib import Path
def extraer_datos(recortar = False, forzar_procesamiento = False, verificar_duraciones = False):
    """Funcion que exporta los datos de actividad y eventos filtrados y corregido. Guarda en un archivo de texto el registro de su actividad y en uno separado por comas los eventos eliminados.

        Los archivos de registro se generan para cada individuo. Ademas genera un archivo .csv, donde guarda los evento eliminados en durante
        el preprocesamiento. Este es necesario para eliminar eventos no adecuadamente registrados en el archivo de la psicometrica. 
        Si la opcion verificar_duraciones se encuentra activa, se borran los registros previos de los sujetos dispuestos a ser procesados.
    recortar : booleano
        Cuando se encuentra activo recorta los espacios entre medio de los eventos que hayan sido descartados
    forzar_procesamiento : booleano
        Cuando se encuentra activo fuerza a reprocesar todos los archivos que encuentre en los directorios indicados
    verificar_duraciones : booleano
        Cuando se encuentra activo verifica las duraciones de los eventos procesados
    """
    # Obtiene la ruta padre es decir, en donde se encuentra este script.
    src_padre = Path(__file__).resolve().parent

    # Crea los directorios por primera vez. Las funciones que exportan tambien intentan realizar esta accion
    ruta_filtrados = src_padre / 'datos_exportados_py' / 'actividad_filtrada'
    ruta_modificados = src_padre / 'datos_exportados_py' / 'eventos_modificados'
    if not ruta_filtrados.is_dir() or not ruta_modificados.is_dir():
        os.makedirs(ruta_filtrados)
        os.makedirs(ruta_modificados)
    # Crea el directorio donde se exportaran los ensayos a eliminar en formato .csv
    ruta_csv = src_padre / 'ensayos_por_eliminar'
    if not ruta_csv.is_dir():
        os.makedirs(ruta_csv)

    src_dir = src_padre / 'datos_exportados_m' / 'eventos_exportados' # Carpeta desde donde se cargan los archivos de eventos

    print(f'Leyendo archivos de la carpeta: {src_dir}')
    files = sorted(src_dir.glob('*.txt')) # Carga todos los archivos de texto en la carpeta, ordenados alfabéticamente
    print(f'Número de archivos encontrados: {len(files)}')
    print(f'Mostrando archivos: {files}')

    os.makedirs(src_padre / 'registros', exist_ok=True) # Crea la carpeta de registros si no existe
        # ! Se configura la salida de los comandos print para que se escriba automaticamente en el archivo de registro

    for file in files:
        sbjct_name_mod = file.stem # Obtiene el nombre del sujeto sin la extensión
        sbjct_name = sbjct_name_mod.replace("_eventos","") # Extrae el nombre del sujeto del experimento

        # Construye las rutas independientemente del sistema operativo y del
        # directorio desde el que se ejecute el script.
        archivo_exportado = ruta_filtrados / f'{sbjct_name}_actividad_filtrada' # Ruta del archivo que se guardará
        archivo_exportado_rec = ruta_filtrados / f'{sbjct_name}_actividad_filtrada_rec'
        path_archivo_registro = src_padre / 'registros' / f'{sbjct_name}_registro_preprocesamiento.txt' # Archivo de registro de procesamiento

        """
         ! Verifica si el archivo de actividad existe, en cuyo caso ejecuta el resto de codigo, 
         ! pero si el archivo ya existe, salta al siguiente sujeto 
        """
        if not forzar_procesamiento:
            if recortar:
                if archivo_exportado_rec.is_file():
                    print(f'Archivo de actividad ya existe. Saltando el procesamiento de {file.name}.')
                    continue
            else:
                if archivo_exportado.is_file():
                    print(f'Archivo de actividad ya existe. Saltando el procesamiento de {file.name}.')
                    continue

        # ! Si forzar procesamiento esta activo, se borra el contenido previo del archivo de registros
        with open(path_archivo_registro, 'w', encoding='utf-8') as archivo_registro: # Abre el archivo de registro en modo write para sobreescribir el contenido previo
            print("--------------------------------------------- INGRESANDO NUEVO REGISTRO ---------------------------------------------", file=archivo_registro)


            print(f'\nArchivo de actividad a exportar: {f"{sbjct_name}_actividad_filtrada"}',file=archivo_registro) # Escribe en el archivo de registro el nombre del archivo que se va a exportar

            print(f'Procesando el sujeto: {sbjct_name}',file=archivo_registro)
            # cargamos los eventos del sujeto para procesarlos
            Hsub_eventos = carga_archivo_eventos(file.name)
            print(f'Número de eventos cargados para {sbjct_name}: {len(Hsub_eventos)}',file=archivo_registro)
            print(Hsub_eventos.head(n=15),file=archivo_registro)
            # filtramos los eventos y los guardamos; registramos numero de ensayos hallados
            num_ensayos, Hsub_eventos_modificados  = modificar_eventos(Hsub_eventos,archivo_registro)
            print(f'Número de ensayos procesados para {sbjct_name}: {num_ensayos}', file=archivo_registro)


            # Para verificar que las duraciones sean correctas, guarda el registro en un archivo de texto
            if verificar_duraciones:
                verif_duraciones(Hsub_eventos_modificados)

            # cargamos datos de actividad y tiempo del sujeto para procesarlos
            Hsub_tiempo, Hsub_actividad = carga_archivo_acttiem(f'time_vector_corrected_{sbjct_name}.csv', f'{sbjct_name}_actividad.txt')
            
            # aplicamos el filtro
            Hsub_filtrada = filtrado_butterworth(Hsub_actividad)
            if recortar:
                # cortamos los datos de los ensayos que hayan sido eliminados, ajustamos duracion de eventos
                actividad_cortada, eventos_cortados = cortar_tiempo_entre_ensayos(Hsub_eventos_modificados, Hsub_filtrada)
                # * guardamos numero de muestras y cabecera del archivo de actividad en el registro
                print(f'Muestras en el archivo del sujeto (recortado) {sbjct_name}: {actividad_cortada.shape[1]}', file=archivo_registro)
                print(pd.DataFrame(actividad_cortada).transpose().head(n=15), file=archivo_registro)
                # * ===============================================================================
                # exportamos los datos
                exportar_eventos(eventos_cortados, f'{sbjct_name}_eventos_modificados_rec') # el archivo que guardará y el nombre del sujeto,
                exportar_actividad(actividad_cortada, f'{sbjct_name}_actividad_filtrada_rec') # el archivo que guardará y el nombre del sujeto, 
                                                                            # sin extensión ni carpeta, solo el nombre del archivo.
                                                                            #  Se guardará en la carpeta 'filtrados'.
            else:
                # * guardamos numero de muestras y cabecera del archivo de actividad en el registro
                print(f'Muestras en el archivo {sbjct_name}: {Hsub_filtrada.shape[1]}', file=archivo_registro)
                print(pd.DataFrame(Hsub_actividad).transpose().head(n=15), file=archivo_registro) 
                # * ===============================================================================
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

        # ? Tambien se puede agregar en otro ciclo si no se quiere interferencia con la validacion de forzar el procesamiento
        # ! Para vertido de eventos eliminados en el csv
        ruta_archivo_csv = ruta_csv / f'{sbjct_name}_eventos_eliminados.csv' # Ruta del archivo CSV que se guardará
        with open(path_archivo_registro, 'r', encoding='utf-8') as archivo_registro:
            patron = r'eliminando ensayo (\d+)' # SOLO DEVUELVE LO QUE ESTA ENTRE PARENTESIS !!1
            eventos = []
            for linea in archivo_registro:
                if re.findall(patron, linea): #Checa que NO devuelva: []
                    eventos.append(re.findall(patron, linea)[-1]) 
            print(eventos)

        if eventos:
            with open(ruta_archivo_csv, 'w', newline='', encoding='utf-8') as archivo_csv:
                escritor = csv.writer(archivo_csv)
                for evento in eventos:
                    escritor.writerow([evento])
                print(f'Registrados ensayos eliminados para {sbjct_name}')
        else:
            print(f'No se encontraron ensayos por eliminar en {sbjct_name}')