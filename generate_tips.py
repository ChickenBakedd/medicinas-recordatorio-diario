import json
import uuid
import random

categories = [
    ("Hidratación", "drop.fill", "blue"),
    ("Descanso", "moon.stars.fill", "indigo"),
    ("Alimentación", "leaf.fill", "green"),
    ("Movimiento", "figure.walk", "orange"),
    ("Corazón", "heart.fill", "red"),
    ("Mente", "brain", "purple"),
    ("Ojos", "eye.fill", "cyan"),
    ("Articulaciones", "figure.flexibility", "teal"),
    ("Piel", "sun.dust.fill", "yellow"),
    ("Digestión", "cup.and.saucer.fill", "brown"),
    ("Inmunidad", "shield.fill", "mint"),
    ("Medicación", "pills.fill", "pink"),
    ("Respiración", "wind", "cyan"),
    ("Metabolismo", "flame.fill", "orange"),
    ("Postura", "figure.mind.and.body", "gray")
]

structures = [
    "Mejora tu {tema} {accion} cada día.",
    "Para proteger tu {tema}, asegúrate de {accion}.",
    "El secreto para un buen estado de {tema} es {accion}.",
    "Nunca olvides {accion} para beneficiar tu {tema}.",
    "Si sientes fatiga, {accion} puede revivir tu {tema}.",
    "Los especialistas en {tema} recomiendan fuertemente {accion}.",
    "Un hábito simple como {accion} transformará tu {tema}.",
    "Tu {tema} te agradecerá infinitamente que empieces a {accion}.",
    "Reduce los problemas de {tema} al {accion} regularmente.",
    "El primer paso hacia un mejor {tema} es {accion} sin excusas.",
    "No subestimes el poder de {accion} para tu {tema}.",
    "Invertir tiempo en {accion} asegura un excelente nivel de {tema}.",
    "A la larga, {accion} es la mejor medicina para tu {tema}.",
    "Si notas molestias, intenta {accion} para relajar tu {tema}.",
    "Un consejo infalible para tu {tema} consiste en {accion}.",
    "Puedes prevenir el desgaste de tu {tema} al {accion}.",
    "La clave oculta para potenciar tu {tema} es simplemente {accion}.",
    "Hazte un favor y empieza a {accion} para cuidar tu {tema}.",
    "Transforma tu día y tu {tema} al {accion} por las mañanas.",
    "Evita complicaciones de {tema} tomando la costumbre de {accion}."
]

acciones = {
    "Hidratación": ["beber al menos 2 litros de agua", "empezar la mañana con un vaso de agua tibia", "evitar los refrescos azucarados", "llevar siempre una botella de agua", "tomar infusiones sin azúcar", "beber antes de tener sed", "consumir frutas ricas en agua como la sandía", "limitar el alcohol que deshidrata", "tomar un vaso de agua antes de cada comida", "reducir el consumo de bebidas energéticas"],
    "Descanso": ["dormir 8 horas diarias", "apagar las pantallas una hora antes de dormir", "mantener la habitación oscura y fresca", "evitar el café después de las 4 PM", "establecer un horario regular para acostarte", "usar tapones para los oídos si hay ruido", "cenar ligero para no alterar el sueño", "practicar meditación antes de dormir", "usar un colchón adecuado y ergonómico", "evitar siestas de más de 30 minutos"],
    "Alimentación": ["comer 5 porciones de fruta y verdura", "evitar los ultraprocesados y grasas trans", "añadir grasas saludables como aguacate", "reducir el consumo de sal", "masticar cada bocado al menos 20 veces", "priorizar los cereales integrales", "incluir una fuente de proteína en cada comida", "cocinar a la plancha o al vapor", "leer siempre las etiquetas nutricionales", "planificar tus menús semanales"],
    "Movimiento": ["caminar 10.000 pasos al día", "hacer estiramientos matutinos", "subir por las escaleras en vez de usar el ascensor", "levantarte de la silla cada hora", "hacer ejercicios de fuerza dos veces por semana", "bailar tu canción favorita a diario", "usar la bicicleta para trayectos cortos", "hacer yoga o pilates regularmente", "nadar un par de veces a la semana", "aparcar el coche un poco más lejos"],
    "Corazón": ["hacer 30 minutos de ejercicio cardiovascular", "controlar tus niveles de colesterol", "reducir el estrés con meditación", "evitar el tabaco por completo", "comer pescado azul rico en Omega-3", "vigilar tu presión arterial periódicamente", "sustituir la sal por especias aromáticas", "consumir aceite de oliva virgen extra", "reír a carcajadas con amigos", "mantener un peso corporal saludable"],
    "Mente": ["leer 15 minutos al día", "aprender algo nuevo cada semana", "hacer pausas activas durante el trabajo", "practicar la respiración profunda", "desconectar del móvil los domingos", "resolver sudokus o crucigramas", "escribir un diario de gratitud", "hablar de tus emociones con alguien de confianza", "pasar tiempo en contacto con la naturaleza", "aprender a decir no sin sentir culpa"],
    "Ojos": ["aplicar la regla 20-20-20 al mirar pantallas", "usar gafas de sol con protección UV", "parpadear conscientemente más a menudo", "bajar el brillo de tus dispositivos", "acudir al oftalmólogo anualmente", "usar lágrimas artificiales si notas sequedad", "ajustar el contraste de tus monitores", "consumir zanahorias y verduras de hoja verde", "mantener una distancia prudencial del televisor", "evitar frotarte los ojos con las manos sucias"],
    "Articulaciones": ["realizar estiramientos suaves", "mantener un peso saludable", "consumir alimentos antiinflamatorios", "hacer ejercicios de bajo impacto como natación", "evitar cargar pesos de forma incorrecta", "calentar siempre antes de hacer deporte", "usar un calzado adecuado y con buena amortiguación", "tomar descansos activos si trabajas de pie", "consumir caldo de huesos rico en colágeno", "hacer ejercicios de movilidad articular al despertar"],
    "Piel": ["aplicar protector solar a diario", "limpiar tu rostro antes de dormir", "mantener una buena hidratación interna", "evitar rascar las picaduras", "consumir alimentos ricos en vitamina C", "usar crema hidratante después de la ducha", "no abusar del agua muy caliente al bañarte", "dormir lo suficiente para reducir las ojeras", "evitar el exceso de maquillaje a diario", "exfoliar suavemente una vez a la semana"],
    "Digestión": ["cenar ligero y dos horas antes de dormir", "consumir probióticos naturales como el kéfir", "evitar comidas muy copiosas o grasientas", "masticar lentamente", "beber infusiones de manzanilla o hinojo", "aumentar el consumo de fibra dietética", "evitar el exceso de bebidas con gas", "identificar y reducir tus intolerancias", "dar un pequeño paseo después de comer", "evitar acostarte justo después de ingerir alimentos"],
    "Inmunidad": ["dormir lo suficiente cada noche", "consumir vitamina C y Zinc", "lavarte las manos con frecuencia", "gestionar bien el estrés crónico", "ventilar las habitaciones todos los días", "consumir ajo crudo o miel con moderación", "mantenerte al día con tus vacunas recomendadas", "hacer ejercicio moderado pero constante", "evitar los cambios bruscos de temperatura", "abrazar a tus seres queridos para aumentar la oxitocina"],
    "Medicación": ["revisar las fechas de caducidad", "consultar a tu farmacéutico sobre interacciones", "tomar la dosis exacta recomendada", "no mezclar pastillas con alcohol", "no dejar los antibióticos a medias", "guardar tus medicamentos en un lugar seco", "usar alarmas para no olvidar ninguna toma", "leer siempre el prospecto antes de tomar algo nuevo", "llevar un registro de lo que tomas", "no automedicarte bajo ninguna circunstancia"],
    "Respiración": ["inhalar por la nariz y exhalar por la boca", "practicar la respiración diafragmática", "evitar zonas con alta contaminación ambiental", "hacer ejercicios de expansión torácica", "usar purificadores de aire en casa", "no fumar ni ser fumador pasivo", "hacer vahos de eucalipto en invierno", "mantener una postura erguida para no oprimir los pulmones", "cantar o tocar un instrumento de viento", "salir a la montaña para respirar aire puro"],
    "Metabolismo": ["desayunar proteínas para activar el cuerpo", "entrenar con pesas para crear músculo", "beber agua fría para generar termogénesis", "evitar saltarte comidas si no haces ayuno controlado", "dormir en una habitación fresca", "tomar té verde o café con moderación", "hacer intervalos de alta intensidad (HIIT)", "aumentar tu actividad no asociada al ejercicio (NEAT)", "comer alimentos ricos en yodo para la tiroides", "evitar las dietas milagro extremadamente restrictivas"],
    "Postura": ["mantener el monitor a la altura de los ojos", "usar una silla ergonómica con soporte lumbar", "repartir el peso en ambas piernas al estar de pie", "no cruzar las piernas durante largos periodos", "usar una mochila en ambos hombros", "estirar los músculos pectorales regularmente", "fortalecer la zona del core (abdominales y lumbares)", "evitar dormir boca abajo", "alinear tus orejas con tus hombros al caminar", "levantar objetos pesados flexionando las rodillas"]
}

tips = []

# Generate 1000
for i in range(1000):
    tema_tuple = random.choice(categories)
    tema_nombre, icono, color = tema_tuple
    
    estructura = random.choice(structures)
    accion = random.choice(acciones[tema_nombre])
    
    descripcion = estructura.format(tema=tema_nombre.lower(), accion=accion)
    descripcion = descripcion[0].upper() + descripcion[1:]
    
    tips.append({
        "id": str(uuid.uuid4()),
        "title": tema_nombre,
        "description": descripcion,
        "icon": icono,
        "color": color
    })

unique_tips = {t["description"]: t for t in tips}.values()
tips_list = list(unique_tips)

while len(tips_list) < 1000:
    tema_tuple = random.choice(categories)
    tema_nombre, icono, color = tema_tuple
    estructura = random.choice(structures)
    accion = random.choice(acciones[tema_nombre])
    descripcion = estructura.format(tema=tema_nombre.lower(), accion=accion)
    descripcion = descripcion[0].upper() + descripcion[1:]
    
    if descripcion not in [t["description"] for t in tips_list]:
        tips_list.append({
            "id": str(uuid.uuid4()),
            "title": tema_nombre,
            "description": descripcion,
            "icon": icono,
            "color": color
        })

tips_list = tips_list[:1000]

with open('Aura Health/Aura Health/Resources/health_tips.json', 'w', encoding='utf-8') as f:
    json.dump(tips_list, f, ensure_ascii=False, indent=4)

print("Created health_tips.json with", len(tips_list), "tips.")
