import pandas as pd
import numpy as np
import os
import matplotlib
matplotlib.use('Agg') # resulta que si se quiere invocar desde MATLAB
                      # se tiene que cargar un backend con matlplotlib
                      # Agg esta hecho para guardar archivos. 
                      # Los demas para uso interactivo, si el backend 
                      # esta mal configurado el codigo da error.
import matplotlib.pyplot as plt
from math import ceil, floor
from pathlib import Path
from scipy import signal
from scipy.signal import butter, lfilter,filtfilt, freqz

# * -------------------------------- Manipulación de datos, archivos y directorios --------------------------------
def carga_archivo_eventos(nombre_sujeto: str) -> pd.DataFrame:
    """Carga un archivo de eventos desde la carpeta de datos.

    Parametros
    ----------
    nombre_sujeto : str
        Nombre del archivo a leer.

    Regresa
    -------
    pd.DataFrame
        DataFrame con los eventos cargados.
    """
    file_path_recort = Path(r'.\datos_exportados_m\eventos_exportados') # COLOCA TU RUTA
                                                                      # Path se encargara de corregirla al SO de tu equipo
    file_path_recort = file_path_recort / nombre_sujeto
    data = pd.read_csv(file_path_recort, sep = r'\s+')
    return data

# ! Aqui en modificar eventos debe exportarse el archivo de eventos
def modificar_eventos(data: pd.DataFrame,archivo_registro) -> tuple[int, pd.DataFrame]:
    """Filtra los eventos que corresponden a ensayos completos y elimina repeticiones de los ensayos 4 y 5; y exporta el archivo con los eventos modificados. Adicionalmente guarda en un archivo de registro los ensayos que fueron eliminados. 

    Parametros
    ----------
    data : pd.DataFrame
        DataFrame original con los eventos.
    archivo_registro : file object
        Archivo de registro donde se guardarán los eventos incompletos pero registrados en la psicofisica. 

    Regresa
    -------
    tuple[int, pd.DataFrame]
        Número de ensayos completos y DataFrame con los eventos filtrados.
    """
    mi_array_ev = np.array(data['type'])
    mis_triggers_verdaderos = np.array([])
    # mis_triggers_conjuntos = np.array([])
    contador_4 = 0
    contador_5 = 0
    ensayos = 0
    ensayos_reales = 0
    posibles = np.zeros(8)

    for idx, trigger in enumerate(mi_array_ev):
    #   print(f"El valor de trigger es {trigger}")
      match trigger:
        case 1:
          # ! (i) Tenemos que agregar una condicion que nos indique si un ensayo se esta eliminando para contar los ensayos totales
          # ! (ii) ¿O la idea es que de los que ya sabemos que tenemos que esperar (198 o 120), indiquemos cual se esta eliminando 
          # ! R: Hay que hacer lo segundo. Esto ya que los ensayos que tienen eventos faltante entre medio SI los registro la psicofisica
          # ! Los que tienen ensayos que no llegan ni al 8 no los registra por que esto solo lo hace con ensayos completos
          # ! la razon de por que de repente faltan entre medio es por que hubo errores en la toma de datos.  
          posibles = np.zeros(8)
          contador_4 = 0
          contador_5 = 0
          posibles[0] = idx
        case 2:
          posibles[1] = idx
        case 3:
          posibles[2] = idx
        case 4:
          if contador_4 == 2:
                posibles[3] = idx
          contador_4 += 1
        case 5:
          if contador_5 == 2:
                posibles[4] = idx
          contador_5 += 1
        case 6:
          posibles[5] = idx
        case 7:
          posibles[6] = idx
        case 8:
          posibles[7] = idx
        #   print(f'Los eventos del ensayo {ensayos+1} han quedado marcados como: {posibles}') # ! asi como esta hacemos lo (ii)
          if np.count_nonzero(posibles) == 8: # validacion que ayuda a reconocer si algun evento intermedio se salto es decir si el ensayo es incompleto
            mis_triggers_verdaderos = np.concatenate((mis_triggers_verdaderos, posibles))
            contador_4 = 0
            contador_5 = 0
            posibles = np.zeros(8)
            ensayos_reales += 1
            ensayos += 1
          elif (posibles[0]==0 and np.count_nonzero(posibles) == 7): # validacion que ayuda a reconocer si algun evento intermedio se salto es decir si el ensayo es incompleto
            mis_triggers_verdaderos = np.concatenate((mis_triggers_verdaderos, posibles))
            contador_4 = 0
            contador_5 = 0
            posibles = np.zeros(8)
            ensayos_reales += 1
            ensayos += 1
          else: # ! si se llega hasta aqui quiere decir que hay algun evento faltante intermedio
            print(f'Ninguna condicion coincidente, eliminando ensayo {ensayos+1}',file=archivo_registro)
            contador_4 = 0
            contador_5 = 0
            posibles = np.zeros(8)
            # ! ver si hay que agregar aquí un 
            ensayos += 1

    mis_triggeritos = np.int64(mis_triggers_verdaderos)
    # mis_triggeritos = mis_triggeritos.astype(int)
    # Al parecer hay una incompatibilidad entre el tipo de dato de numpy y el del pdframe
    # a pesar de ello el codigo funciona. La linea comentada sirve para eliminar el problema, 
    # pero no se como afecta el rendimiento.
    # ! Parece ser que no hace falta sumar +1 a los indices 
    # ! en el caso del prepro implementado de esta forma 
    mis_eventos = data.loc[data.index.intersection(mis_triggeritos)].sort_index() # Intersections devuelve etiquetas tipo indice
                                                                                    # del pdframe que coincidan entre triguertios y data
                                                                                    # Luego con loc se toma un subconjunto del pdframe y
                                                                                    # por ultimo se ordenan los eventos.
    # funcion_redondeo = lambda x: f"{float(x):.6f}" # funcion que se aplica a
                                                   # varios campos del dataset
                                                   # para redondear sus valores. 
                                                   # Aunque convierte a string
                                                   # Cambiamos a metodo round(). 
    mis_eventos['type'] = mis_eventos['type']
    mis_eventos = mis_eventos.drop(columns=['number'])
    # mis_eventos['position'] = mis_eventos['position'].apply(funcion_redondeo)
    mis_eventos['latency'] = mis_eventos['latency'].round(6)
    mis_eventos['urevent'] = mis_eventos['urevent'].round(6)
    mis_eventos['duration'] = mis_eventos['duration'].round(6)

    return ensayos_reales, mis_eventos

def exportar_eventos(eventos,nombre:str):

    """Exporta un DataFrame de eventos a un archivo CSV en la carpeta "eventos_modificados".
    Parametros
    ----------
    nombre : str
    Nombre del archivo usado para identificar la salida.
    Regresa
    ----------
    None
    Guarda los datos en la carpeta de eventos_modificados.
    """

    # Ruta completa para el archivo exportado en la carpeta "exportados_paso1"
    # output_dir = os.path.join(os.path.dirname(nombre), 'exportados_paso1')
    # output_path = os.path.join(output_dir, os.path.basename(nombre))
    out_dir = Path(r'.\datos_exportados_py\eventos_modificados')
    output_path = out_dir / f'{nombre}.csv' # Ruta completa para el archivo exportado en la carpeta "eventos_modificados"
    
    os.makedirs(out_dir, exist_ok=True) # Crea el directorio si no existe

    # Exportar el archivo
    eventos.to_csv(output_path, sep='\t', index=False)

# Funcion exploratoria. No es relamente relevante. Mer dice que la podemos quitar
def verif_duraciones(mis_eventos):
    """Calcula la duración previa y posterior al estímulo por ensayo.

    Parametros
    ----------
    mis_eventos : pd.DataFrame
        DataFrame con columnas de tipo y latencia.

    Regresa
    -------
    None
        Imprime las duraciones en segundos para cada ensayo.
    """
    mis_eventos['latency'] = mis_eventos['latency'].astype(float) # convierte a flotante la latencia y el num del evento
    mis_eventos['type'] = mis_eventos['type'].astype(float)
    matriz_interes = mis_eventos[['type', 'latency']] # crea matriz solo con esas 2 variables de interés
    matriz_eventos = matriz_interes.to_numpy() # se convierte de PDdataframe a NParray
    n = 8 # num eventos por ensayo
    ensayos_div = np.split(matriz_eventos, np.arange(n, len(matriz_eventos), n)) # divide en ensayos los eventos y sus latencias
    # hallar la duración desde el inicio del estímulo
    antes_estimulo = []
    despues_estimulo = []

    for group in ensayos_div:
        if len(group) >= 8:  # Asegurarse de que el grupo tiene al menos 8 filas
            primer_value = group[2, 1]  # Primer valor (latencia de la primera fila)
            estimulo_value = group[3, 1]  # Octavo valor (latencia de la octava fila)
            estimulo_acaba_value = group[4, 1]
            ultimo_value = group[6, 1]

        # Calcular la resta
        difference_1 = estimulo_value - primer_value
        antes_estimulo.append(difference_1)

        difference_2 = ultimo_value - estimulo_value
        despues_estimulo.append(difference_2)

    # Convertir las listas a matrices numpy
    antes_estimulo = np.array(antes_estimulo)
    despues_estimulo = np.array(despues_estimulo)

    antesesti_seg = antes_estimulo / 250 # dividir por el la tasa de muestreo para obtener segundos
    despuesesti_seg = despues_estimulo /250

    path_registro_duraciones = Path(r'.\registros\registro_duraciones_preprocesamiento.txt') # Archivo de registro de procesamiento
    registro_duraciones = open(path_registro_duraciones, 'a', encoding='utf-8')

    print(f"Antes del estímulo: {antesesti_seg}", file=registro_duraciones)
    print(f"Después del estímulo: {despuesesti_seg}", file=registro_duraciones)
    registro_duraciones.close()

def carga_archivo_acttiem(nombre_sujeto_tiempo, nombre_sujeto_actividad):
    """Carga los vectores de tiempo y actividad de un sujeto.

    Parametros
    ----------
    nombre_sujeto_tiempo : str
        Nombre del archivo con las muestras temporales.
    nombre_sujeto_actividad : str
        Nombre del archivo con la actividad de los electrodos.

    Regresa
    -------
    tuple[np.ndarray, pd.DataFrame]
        Tiempo y DataFrame con la actividad.
    """
    act_dir = Path(r'.\datos_exportados_m\actividad_exportada')
    time_dir = Path(r'.\datos_exportados_m\tiempos_exportados')
    time_csv_path = time_dir / nombre_sujeto_tiempo
    activity_txt_path = act_dir / nombre_sujeto_actividad
    time_data = pd.read_csv(time_csv_path, sep=r'\s+')
    actividad = pd.read_csv(activity_txt_path, sep='\t', header=0)  # Ajusta 'sep' si es necesario
    # Convertir el DataFrame a un array de numpy (opcional)
    time_data = time_data.to_numpy()
    tiempo = time_data.flatten()
    print(np.shape(tiempo))
    print(np.shape(actividad['FP1']))
    # Verificar que son correctos
    verif = len(actividad['FP2']) == len(tiempo) # Debe ser TRUE
    print(verif)
    if verif == False:
        if tiempo[0]==0:
            pass
        else:
            tiempo = np.insert(tiempo, 0, 0)
    verif = len(actividad['FP2']) == len(tiempo) # Debe ser TRUE
    print("después de verificar:", verif)
    return tiempo, actividad

# podria optimizarse cambiando las copias por modificaciones in situ de los argumentos ? No por que los objetos tipo lista son mutables
# es decir se modifican fuera de la funcion. Ello podria causar conflictos
def cortar_tiempo_entre_ensayos(eventos,actividad,tresh=0.7):
    """Corta la actividad entre ensayos según la latencia de los eventos.
    
        tresh : float, optional
        Umbral que decide si se realiza el corte de la actividad entre ensayos
    """
    filtrado = eventos.copy()
    actividad_final = actividad.copy()
    eventos_ajustados = eventos.copy()
    col_latency = eventos_ajustados.columns.get_loc("latency") # nos guarda el indice de la columna con las latencias
    print(eventos)
    filtrado = filtrado.iloc[1:-1] # devuelve todas las filas excepto la primera (creo que con mi archivo de datos no jalaria)
    #print(filtrado.head(5))
    filtrado_tipo1 = filtrado[filtrado['type'] == 1] # regresa las filas de datos que cumplan la condicion sobre el tipo de evento
    filtrado_tipo8 = filtrado[filtrado['type'] == 8] # por defecto ya estan ordenadas en orden de aparicion
    distancia_entre_eventos = (filtrado_tipo1["latency"].values - filtrado_tipo8["latency"].values)
    print("--------------------------------------------------------------------------------------")
    print(f'El vector de distancia entre eventos es: {distancia_entre_eventos}')
    ajustes = len(distancia_entre_eventos)
    print(f'La cantidad de espacios entre eventos es: {ajustes}')
    print("--------------------------------------------------------------------------------------")
    distancia_base = min(distancia_entre_eventos)
    # corta exactamente a la mitad y si es impar izquierda es el entero mas cercano por abajo y la derecha el mas cercano por arriba de modo que al sumarlos den exactamente la distancia entre eventos.
    distancia_base_izquierda = floor(distancia_base*0.5)
    distancia_base_derecha = ceil(distancia_base*0.5)
    distancia_ajuste = distancia_entre_eventos - distancia_base # distancia sobrante al restar la distancia entre eventos 
                                                                # y la minima distancia del conjunto de los mismos 
    print(f'El vector cuyas entradas son los anchos de los intervalo a recortar es: {distancia_ajuste}')
    print("--------------------------------------------------------")
    print(f'Forma(shape) de la actividad: {actividad.shape}')
    # print(f'actividad[1]: {actividad[1]}')
    latencias8 = filtrado_tipo8["latency"].tolist()
    latencias1 = filtrado_tipo1["latency"].tolist()
    suma_acumulada = 0
    for i in range(ajustes):
#----------------------------------------------------NOTA SUPER IMPORTANTE------------------------------------------------------------------
# si modificamos el corte mitad mitad hay que corregir la deuda de tiempo y que coincida con el redondeo para que todo funcione correctamente
        
        if distancia_ajuste[i] > distancia_base*(tresh):
            # si la distancia sobrante es mayor al 70 por ciento de la distancia minima, se recorta la actividad.
            # el chequeo se realiza para no tomar en cuenta ensayos ligeramente mas largos causados por estadistica.
            latencia_izquierda = (latencias8[i] + distancia_base_izquierda) - suma_acumulada # calcula los bordes del intervalo a eliminar, tomando en cuenta el desplazamiento 
            latencia_derecha = (latencias1[i] - distancia_base_derecha) - suma_acumulada     # previo de la actividad por los cortes anteriores
            actividad_final = np.delete(actividad_final, slice(int(latencia_izquierda), int(latencia_derecha)), axis=1) # elimina el segmento de actividad sobrante entre ensayos, 
                                                                                                                        # la 'linea temporal' se ajusta automaticamente porque todo 
                                                                                                                        # esta expresado en samples, es decir enteros, indices de las columnas
            id_evento_actual = filtrado_tipo1.index[i]
            posicion_fila_real = eventos_ajustados.index.get_loc(id_evento_actual)
            eventos_ajustados.iloc[posicion_fila_real:, col_latency] -= distancia_ajuste[i]
            suma_acumulada += distancia_ajuste[i] # hay que restar por suma acumulada pues hemos recorrido la linea temporal por haber elminado un intervalo de la actividad 
        # else: 
            # print(f"El ensayo (modificado) {i+1} es ligeramente mas largo que el minimo, no se recorta la actividad.")

    print(f'La forma de la actividad luego de ser recortada es: {np.shape(actividad_final)}')
    return actividad_final, eventos_ajustados

def exportar_actividad(datafiltrada, nombre):
    """Exporta una matriz filtrada a un archivo de texto.

    Parametros
    ----------
    datafiltrada : np.ndarray
        Matriz con los datos filtrados.
    nombre : str
        Nombre del archivo de salida.

    Regresa
    -------
    None
        Guarda los datos en la carpeta correspondiente.
    """

    datafiltrada = datafiltrada.T

    out_dir = Path(r'.\datos_exportados_py\actividad_filtrada') # COLOCA TU RUTA
    out_file = out_dir / nombre

    os.makedirs(out_dir, exist_ok=True)
    # Exportar la matriz a un archivo de texto
    np.savetxt(out_file, datafiltrada, delimiter='\t')
    print(f'Datos exportados a {out_file}')

# *-------------------------------- Filtros --------------------------------

def butter_bandpass(lowcut:float, highcut:float, fs:float, order=4):
    """Construye un filtro pasabanda Butterworth, calculando los coeficientes del filtro 

    Parametros
    ----------
    lowcut : float
        Frecuencia de corte inferior.
    highcut : float
        Frecuencia de corte superior.
    fs : float
        Frecuencia de muestreo.
    order : int, optional
        Orden del filtro.

    Regresa
    ----------
    tuple
        Coeficientes del filtro Butterworth, en orden 'b' y 'a'.
    """
    return butter(order, [lowcut, highcut], fs=fs, btype='band',output='ba') # Es un tipo de filtro IIR

def butter_bandpass_filter(data, lowcut, highcut, fs, order=4):
    """Aplica un filtro pasabanda a una señal.

    Parametros
    ----------
    data : array-like
        Señal a filtrar.
    lowcut : float
        Frecuencia de corte inferior.
    highcut : float
        Frecuencia de corte superior.
    fs : float
        Frecuencia de muestreo.
    order : int, optional
        Orden del filtro.

    Regresa
    ----------
    np.ndarray
        Señal filtrada.
    """
    b, a = butter_bandpass(lowcut, highcut, fs, order=order) # Calcula coeficientes del filtro Butterworth
    y = lfilter(b, a, data) # Aplica el filtro a la señal usando lfilter (filtrado causal). Induce retardo de fase.
    #y = filtfilt(b, a, data)
    return y

def filtrado_butterworth(actividad, fs=250, lowcut=0.5, highcut=50, lenChannels = 32, orden=4):
    """Filtra cada canal con un filtro Butterworth pasabanda.

    Parametros
    ----------
    actividad : pd.DataFrame
        Matriz de actividad con canales como columnas.
    fs : float, optional
        Frecuencia de muestreo.
    lowcut : float, optional
        Frecuencia de corte inferior.
    highcut : float, optional
        Frecuencia de corte superior.
    lenChannels : int, optional
        Número de canales a procesar.
    orden : int, optional
        Orden del filtro.

    Regresa
    -------
    np.ndarray
        Señal filtrada con forma (canales, tiempo).
    """
    SignF = actividad.T.to_numpy() # transpuesta para que tenga la forma de (electrodos, muestras)
    #SignF = actividad.T
    filtered = []
    for i in range(0,lenChannels):
        filtered.append(butter_bandpass_filter(SignF[i, :], lowcut, highcut, fs, order = orden)) #entre 3 y 5 order

    DataFiltBP = np.array(filtered)
    print(np.shape(DataFiltBP)) # El shape debe ser (num electrodos, num muestras)
    return DataFiltBP    

# *-------------------------------- Graficación --------------------------------
def graficar_datos(sujeto,tiempo, actividad, electrodo, estado, nombreelect, ylim= [-300, 300]):
  """Grafica la señal original y el promedio por electrodo.

  Parametros
  ----------
  tiempo : array-like
      Vector de tiempo en segundos.
  actividad : pd.DataFrame or np.ndarray
      Matriz con la actividad registrada.
  electrodo : int or str
      Nombre del electrodo a visualizar.
  estado : str
      Etiqueta que indica si la señal corresponde al estado previo o posterior a la aplicacion del filtro.
  nombreelect : str
      Nombre del electrodo para mostrar en la leyenda.
  ylim : list, optional
      Límites del eje vertical para el promedio.

  Regresa
  -------
  None
      Guarda la figura en la carpeta de salida.
  """
  fig, axs = plt.subplots(2,figsize=(10,8))
  titulo = f'{sujeto} Actividad antes del filtro' if estado=='antes' else f'{sujeto} Actividad después del filtro'
  fig.suptitle(titulo)
  axs[0].plot(tiempo, actividad[electrodo])
  axs[0].set_title("Actividad del electrodo: " + (electrodo if estado=='antes' else nombreelect) )
  axs[1].plot(tiempo, np.mean( (actividad if estado=='antes' else actividad.T), axis=1))
  axs[1].set_title("Promedio de actividad de todos los electrodos: " + estado)
  axs[1].set_ylim(ylim)

  for ax in axs.flat:
    ax.set(xlabel='Tiempo (s)', ylabel='Amplitud')

  # Hide x labels and tick labels for top plots and y ticks for right plots.
  for ax in axs.flat:
    ax.label_outer()
	
  plt.tight_layout() # previene encimado de etiquetas
  
  os.makedirs("figuras", exist_ok=True) # Crea el directorio si no existe

  # Guardado de las figuras
  fig.savefig(f'figuras/actividad_{estado}_{nombreelect}_{sujeto}.png', dpi=450, bbox_inches='tight')
                                  # bbox_inches='tight' recorta el espacio blanco
                                  # sobrante y evita que las etiquetas sean recortadas

def graficar_comparacion(sujeto, tiempo, actividad, senhalfiltrada, numelectrodo, electrodo, fs=250, order=4, lowcut = 0.5, highcut = 50):
    """Compara visualmente una señal original y su versión filtrada.

    Parametros
    ----------
    sujeto : str
        Nombre del sujeto.
    tiempo : array-like
        Vector de tiempo.
    actividad : pd.DataFrame or np.ndarray
        Señal original.
    senhalfiltrada : np.ndarray
        Señal ya filtrada.
    numelectrodo : int
        Índice del canal filtrado.
    electrodo : str
        Nombre del electrodo mostrado.
    fs : float, optional
        Frecuencia de muestreo.
    order : int, optional
        Orden del filtro.
    lowcut : float, optional
        Frecuencia de corte inferior.
    highcut : float, optional
        Frecuencia de corte superior.

    Regresa
    -------
    None
        Guarda la comparación en disco.
    """
    plt.figure(figsize=(14, 8))
    # Señal original
    plt.subplot(3, 1, 1)
    plt.suptitle(f"Comparación entre señales de {sujeto} antes y después de filtrar", fontsize=14)
    plt.plot(tiempo, actividad[electrodo], color="slategray")
    plt.title('Señal Original del electrodo ' + electrodo)
    plt.xlabel('Tiempo [s]')
    plt.ylabel('Amplitud')
    plt.ylim(-200, 200)

    # Señal filtrada
    plt.subplot(3, 1, 2)
    plt.plot(tiempo, senhalfiltrada[numelectrodo], color="slategray")
    plt.title('Señal Filtrada del electrodo ' + electrodo)
    plt.xlabel('Tiempo [s]')
    plt.ylabel('Amplitud')
    plt.ylim(-200, 200)

    # Respuesta en frecuencia del filtro
    plt.subplot(3, 1, 3)
    b, a = butter_bandpass(lowcut, highcut, fs, order)
    w, h = freqz(b, a, worN=8000)
    plt.plot(0.5 * fs * w / np.pi, np.abs(h), color="deepskyblue")
    plt.title('Respuesta en Frecuencia del Filtro')
    plt.xlabel('Frecuencia [Hz]')
    plt.ylabel('Ganancia')
    plt.grid()
    plt.axvline(lowcut, color='r', linestyle='--')
    plt.axvline(highcut, color='r', linestyle='--')
    plt.xlim(0, 0.5 * fs)

    plt.tight_layout()

    os.makedirs("figuras", exist_ok=True) # Crea la carpeta "figuras" si no existe
    
    plt.savefig(f"figuras/ejemplo_filtrado_modif_{sujeto}.png", dpi=300, bbox_inches='tight')
    plt.close()
    # plt.show()