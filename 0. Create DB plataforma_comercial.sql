-- Crear base de datos
CREATE DATABASE IF NOT EXISTS plataforma_multinivel;
USE plataforma_multinivel;

-- Desactiva FK para evitar problemas de orden durante la creación */
SET FOREIGN_KEY_CHECKS = 0;

-- Tabla: countries (países)
CREATE TABLE countries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- Tabla: stateregions (departamentos o estados)
CREATE TABLE stateregions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    id_pais INT NOT NULL,
    FOREIGN KEY (id_pais) REFERENCES countries(id)
) ENGINE=InnoDB;

-- Tabla: citiesormunicipalities (ciudades o municipios)
CREATE TABLE citiesormunicipalities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    id_region INT NOT NULL,
    FOREIGN KEY (id_region) REFERENCES stateregions(id)
) ENGINE=InnoDB;

-- Tabla: audiences (audiencias)
CREATE TABLE audiences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- Tabla: customers (clientes)
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) UNIQUE,
    telefono VARCHAR(20),
    id_ciudad INT NOT NULL,
    id_audiencia INT,
    id_membresia INT NOT NULL,
    FOREIGN KEY (id_ciudad) REFERENCES citiesormunicipalities(id),
    FOREIGN KEY (id_audiencia) REFERENCES audiences(id),
    FOREIGN KEY (id_membresia) REFERENCES memberships(id)
) ENGINE=InnoDB;

-- Tabla: companies (empresas)
CREATE TABLE companies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(50),
    categoria VARCHAR(50),
    id_ciudad INT NOT NULL,
    id_audiencia INT,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ciudad) REFERENCES citiesormunicipalities(id),
    FOREIGN KEY (id_audiencia) REFERENCES audiences(id)
) ENGINE=InnoDB;

-- Tabla: products (productos)
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL,
    categoria VARCHAR(50),
    imagen TEXT,
    prom_califica DECIMAL(10, 2) NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unidad_medida VARCHAR(50)
) ENGINE=InnoDB;

-- Tabla: companyproducts (relación empresa-producto)
CREATE TABLE companyproducts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_empresa INT NOT NULL,
    id_producto INT NOT NULL,
    precio DECIMAL(10, 2),
    unidad_medida VARCHAR(50),
    FOREIGN KEY (id_empresa) REFERENCES companies(id),
    FOREIGN KEY (id_producto) REFERENCES products(id)
) ENGINE=InnoDB;

-- Tabla: polls (encuestas)
CREATE TABLE polls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_inicio    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          VARCHAR(20) DEFAULT 'ACTIVA'  -- Ej: 'ACTIVA', 'INACTIVA'
) ENGINE=InnoDB;

-- Tabla: rates (valoraciones)
CREATE TABLE rates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_producto_empresa INT NOT NULL,
    puntuacion TINYINT NOT NULL,
    comentario TEXT,
    fecha DATE NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES customers(id),
    FOREIGN KEY (id_producto_empresa) REFERENCES companyproducts(id)
) ENGINE=InnoDB;

-- Tabla: quality_products (calidad de productos)
CREATE TABLE quality_products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_encuesta INT NOT NULL,
    id_producto_empresa INT NOT NULL,
    id_cliente INT,
    resultado TEXT,
    FOREIGN KEY (id_encuesta) REFERENCES polls(id),
    FOREIGN KEY (id_producto_empresa) REFERENCES companyproducts(id),
    FOREIGN KEY (id_cliente) REFERENCES customers(id)
) ENGINE=InnoDB;

-- Tabla: favorites (favoritos)
CREATE TABLE favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    nombre_lista VARCHAR(100),
    FOREIGN KEY (id_cliente) REFERENCES customers(id)
) ENGINE=InnoDB;

-- Tabla: details_favorites (detalles de favoritos)
CREATE TABLE details_favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_lista INT NOT NULL,
    id_producto_empresa INT NOT NULL,
    FOREIGN KEY (id_lista) REFERENCES favorites(id),
    FOREIGN KEY (id_producto_empresa) REFERENCES companyproducts(id)
) ENGINE=InnoDB;

-- Tabla: memberships (membresías)
CREATE TABLE memberships (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
) ENGINE=InnoDB;

-- Tabla: membershipperiods (periodos de membresía)
CREATE TABLE membershipperiods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_membresia INT NOT NULL,
    inicio DATE NOT NULL,
    fin DATE NOT NULL,
    costo DECIMAL(10,2),
    pago_confirmado  BOOLEAN NOT NULL DEFAULT FALSE,
    status           VARCHAR(20) DEFAULT 'INACTIVA',
    FOREIGN KEY (id_membresia) REFERENCES memberships(id)
) ENGINE=InnoDB;

-- Tabla: benefits (beneficios)
CREATE TABLE benefits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    descripcion TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabla: audiencebenefits (audiencia-beneficio)
CREATE TABLE audiencebenefits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_audiencia INT NOT NULL,
    id_beneficio INT NOT NULL,
    FOREIGN KEY (id_audiencia) REFERENCES audiences(id),
    FOREIGN KEY (id_beneficio) REFERENCES benefits(id)
) ENGINE=InnoDB;

-- Tabla: membershipbenefits (membresía-beneficio)
CREATE TABLE membershipbenefits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_membresia INT NOT NULL,
    id_beneficio INT NOT NULL,
    FOREIGN KEY (id_membresia) REFERENCES memberships(id),
    FOREIGN KEY (id_beneficio) REFERENCES benefits(id)
) ENGINE=InnoDB;

CREATE TABLE log_acciones (
  id int NOT NULL AUTO_INCREMENT,
  id_entidad int NOT NULL,
  entidad varchar(50) NOT NULL,
  descripcion text NOT NULL,
  fecha timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE log_estados (
  id int NOT NULL AUTO_INCREMENT,
  id_entidad int NOT NULL,
  entidad varchar(50) NOT NULL,
  estado_nuevo varchar(50) NOT NULL,
  fecha timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE notificaciones (
  id int NOT NULL AUTO_INCREMENT,
  cliente_id int NOT NULL,
  mensaje text NOT NULL,
  fecha timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

/* ------------------------------------------------------------
   Activamos de nuevo las restricciones de clave foránea
   ------------------------------------------------------------ */
SET FOREIGN_KEY_CHECKS = 1;