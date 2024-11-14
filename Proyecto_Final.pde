import java.util.Arrays;

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress pdAddress;

color[] buttonColors;
String[] headersNames;
String[] Countries;
String[] years;
float buttonDiameter;
int selectedColor;
String selectedMetric;
Table tabla;
HashMap<String, HashMap<String, Float>> countryData;
int topMargin = 100; // Aumentar margen superior para el título
float minRectHeight = 20; // Altura mínima de los rectángulos


void sendOSCDataButton() {
  OscMessage message = new OscMessage("/button");

  message.add(1);     // Posición X del círculo
  //message.add(y);     // Posición Y del círculo
  // Enviar mensaje a Pure Data
  oscP5.send(message, pdAddress);
}


void setup() {
  
  oscP5 = new OscP5(this, 10000); // Puerto de Processing
  pdAddress = new NetAddress("192.168.1.94", 8000);
  
  fullScreen();
  buttonColors = new color[] {
    color(255, 0, 0),    // Rojo para GDP
    color(0, 255, 0),    // Verde para Population
    color(0, 255, 255),  // Cian para Life Expectancy
    color(0, 0, 255),    // Azul para Unemployment Rate
    color(128, 0, 255),  // Morado para CO2 Emissions
    color(255, 0, 255)   // Rosa para Access to Electricity
  };
  buttonDiameter = width / 30.0;
  selectedColor = color(255);
  textAlign(CENTER, CENTER);
  textSize(20);

  // Inicializar datos y cargar tabla
  Countries = new String[] {"Brazil", "Canada", "Saudi Arabia", "United States", "China", "Italy", "Australia", "South Africa", "Argentina", "Japan", "Germany", "India"};
  years = new String[]{"2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019"};
  headersNames = new String[]{"GDP (USD)", "Population", "Life Expectancy", "Unemployment Rate (%)", "CO2 Emissions (metric tons per capita)", "Access to Electricity (%)"};
  
  selectedMetric = headersNames[0]; // Inicializa la métrica seleccionada
  loadData();
}

void sendOSCDataMouse(float x) {
  OscMessage message = new OscMessage("/mouse");

  message.add(x);     // Posición X del círculo
  //message.add(y);     // Posición Y del círculo
  // Enviar mensaje a Pure Data
  oscP5.send(message, pdAddress);
}

void draw() {
  int yearIndex = (int) map(mouseX, 0, width, 0, years.length - 1); // Cambia el año según la posición del mouse
  yearIndex = constrain(yearIndex, 0, years.length - 1); // Asegúrate de que el índice esté dentro del rango
  String year = years[yearIndex];
  float x = map(mouseX, 0, 1916, 0, 1);
  sendOSCDataMouse(x);
  displayDataForYear(year); // Mostrar datos para el año seleccionado
  drawButtons();
  drawTitle(year); // Mostrar título en la parte superior
}

// Función para cargar los datos del CSV
void loadData() {
  tabla = loadTable("world_bank_dataset.csv", "header");
  countryData = new HashMap<String, HashMap<String, Float>>();

  for (String country : Countries) {
    HashMap<String, Float> yearData = new HashMap<String, Float>();

    // Filtrar las filas que coincidan con el país
    Iterable<TableRow> rows = tabla.findRows(country, "Country");
    
    for (TableRow row : rows) {
      String year = row.getString("Year");
      
      if (year != null && Arrays.asList(years).contains(year)) {
        Float value = row.getFloat(selectedMetric);
        yearData.put(year, value);
      }
    }
    countryData.put(country, yearData);
  }
}

// Mostrar datos para el año específico
void displayDataForYear(String year) {
  background(255);

  float rectWidth = width / Countries.length; // Ancho de cada rectángulo
  for (int i = 0; i < Countries.length; i++) {
    String country = Countries[i];
    HashMap<String, Float> yearData = countryData.get(country);
    
    float value;
    if (yearData != null && yearData.containsKey(year)) {
      value = yearData.get(year);
    } else {
      value = 0; // Si no hay datos, establecer valor en 0
    }
    
    float maxValue = getMaxValue(selectedMetric, year);
    
    // Escalar el valor y ajustar el color de azul
    float intensity = map(value, 0, maxValue, 0, 255);
    color countryColor = color(0, 0, intensity);
    
    // Calcular la altura del rectángulo y aplicar altura mínima
    float rectHeight = max(map(value, 0, maxValue, minRectHeight, height - topMargin), minRectHeight);
    
    // Dibujar rectángulo vertical y mostrar valor
    fill(countryColor);
    rect(i * rectWidth, height - rectHeight, rectWidth, rectHeight);
    
    fill(0); // Texto en negro
    String displayValue = (value == 0) ? "NA" : nf(value, 0, 2); // Mostrar "NA" si el valor es 0
    text(country + ": " + displayValue, i * rectWidth + rectWidth / 2, height - rectHeight - 10);
  }
}

// Obtiene el valor máximo para la métrica seleccionada en un año específico
float getMaxValue(String metric, String year) {
  float maxValue = -1;
  for (String country : Countries) {
    HashMap<String, Float> yearData = countryData.get(country);
    if (yearData != null && yearData.containsKey(year)) {
      float value = yearData.get(year);
      if (value > maxValue) {
        maxValue = value;
      }
    }
  }
  return maxValue;
}

// Dibuja los botones para seleccionar métricas
void drawButtons() {
  float spacing = width / (buttonColors.length + 1);
  float y = height * 0.9;
  float textY = y + buttonDiameter * 0.8;

  for (int i = 0; i < buttonColors.length; i++) {
    float x = spacing * (i + 1);
    fill(buttonColors[i]);
    noStroke();
    ellipse(x, y, buttonDiameter, buttonDiameter);
    
    fill(0);
    textSize(20);
    text(headersNames[i], x, textY);
  }
}

// Cambia la métrica seleccionada al hacer clic en un botón
void mousePressed() {
  float spacing = width / (buttonColors.length + 1);
  float y = height * 0.9;

  for (int i = 0; i < buttonColors.length; i++) {
    float x = spacing * (i + 1);
    if (dist(mouseX, mouseY, x, y) < buttonDiameter / 2) {
      selectedMetric = headersNames[i];
      loadData(); // Recargar datos con la nueva métrica seleccionada
      sendOSCDataButton();
      break;
    }
  }
}

// Dibuja el título en la parte superior, mostrando la métrica seleccionada y el año
void drawTitle(String year) {
  fill(0);
  textSize(24);
  String titleText = selectedMetric + " - Year: " + (year == null ? "NA" : year);
  text(titleText, width / 2, topMargin / 2);
}
