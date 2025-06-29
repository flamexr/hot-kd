-- K/D Script Database Setup
-- Bu dosyayı MySQL veritabanınızda çalıştırın

-- Veritabanı oluştur (isteğe bağlı)
-- CREATE DATABASE IF NOT EXISTS fivem_server;
-- USE fivem_server;

-- Player K/D tablosunu oluştur
CREATE TABLE IF NOT EXISTS `player_kd` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL UNIQUE,
    `kills` INT DEFAULT 0,
    `deaths` INT DEFAULT 0,
    `kd_ratio` DECIMAL(10,2) DEFAULT 0.00,
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_kd_ratio` (`kd_ratio`),
    INDEX `idx_kills` (`kills`)
);

-- K/D istatistikleri tablosu (opsiyonel - genel istatistikler için)
CREATE TABLE IF NOT EXISTS `kd_statistics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `total_kills` BIGINT DEFAULT 0,
    `total_deaths` BIGINT DEFAULT 0,
    `total_players` INT DEFAULT 0,
    `average_kd` DECIMAL(10,2) DEFAULT 0.00,
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- İlk istatistik kaydını ekle
INSERT INTO `kd_statistics` (`total_kills`, `total_deaths`, `total_players`, `average_kd`) 
VALUES (0, 0, 0, 0.00) 
ON DUPLICATE KEY UPDATE `last_updated` = CURRENT_TIMESTAMP;

-- K/D geçmişi tablosu (opsiyonel - kill/death geçmişi için)
CREATE TABLE IF NOT EXISTS `kd_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL,
    `action_type` ENUM('kill', 'death') NOT NULL,
    `victim_identifier` VARCHAR(50) NULL,
    `killer_identifier` VARCHAR(50) NULL,
    `weapon` VARCHAR(100) NULL,
    `location` VARCHAR(255) NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_action_type` (`action_type`),
    INDEX `idx_timestamp` (`timestamp`)
);

-- Stored Procedure: K/D oranını hesapla ve güncelle
DELIMITER //
CREATE PROCEDURE UpdatePlayerKD(IN player_identifier VARCHAR(50))
BEGIN
    DECLARE kill_count INT DEFAULT 0;
    DECLARE death_count INT DEFAULT 0;
    DECLARE kd_ratio_calc DECIMAL(10,2) DEFAULT 0.00;
    
    -- Mevcut kill ve death sayılarını al
    SELECT kills, deaths INTO kill_count, death_count 
    FROM player_kd 
    WHERE identifier = player_identifier;
    
    -- K/D oranını hesapla
    IF death_count = 0 THEN
        SET kd_ratio_calc = kill_count;
    ELSE
        SET kd_ratio_calc = ROUND(kill_count / death_count, 2);
    END IF;
    
    -- K/D oranını güncelle
    UPDATE player_kd 
    SET kd_ratio = kd_ratio_calc, last_updated = CURRENT_TIMESTAMP 
    WHERE identifier = player_identifier;
END //
DELIMITER ;

-- Stored Procedure: Genel istatistikleri güncelle
DELIMITER //
CREATE PROCEDURE UpdateGlobalStats()
BEGIN
    DECLARE total_k BIGINT DEFAULT 0;
    DECLARE total_d BIGINT DEFAULT 0;
    DECLARE total_p INT DEFAULT 0;
    DECLARE avg_kd DECIMAL(10,2) DEFAULT 0.00;
    
    -- Toplam değerleri hesapla
    SELECT 
        COALESCE(SUM(kills), 0),
        COALESCE(SUM(deaths), 0),
        COUNT(*),
        COALESCE(AVG(kd_ratio), 0.00)
    INTO total_k, total_d, total_p, avg_kd
    FROM player_kd;
    
    -- Genel istatistikleri güncelle
    UPDATE kd_statistics 
    SET 
        total_kills = total_k,
        total_deaths = total_d,
        total_players = total_p,
        average_kd = ROUND(avg_kd, 2),
        last_updated = CURRENT_TIMESTAMP
    WHERE id = 1;
END //
DELIMITER ;

-- Trigger: Player K/D güncellendiğinde genel istatistikleri güncelle
DELIMITER //
CREATE TRIGGER update_global_stats_after_kd_update
AFTER UPDATE ON player_kd
FOR EACH ROW
BEGIN
    CALL UpdateGlobalStats();
END //
DELIMITER ;

-- View: En iyi K/D oranları
CREATE VIEW top_kd_players AS
SELECT 
    identifier,
    kills,
    deaths,
    kd_ratio,
    last_updated,
    RANK() OVER (ORDER BY kd_ratio DESC, kills DESC) as ranking
FROM player_kd
WHERE kills >= 5  -- En az 5 kill şartı
ORDER BY kd_ratio DESC, kills DESC
LIMIT 100;

-- View: Genel istatistikler
CREATE VIEW kd_overview AS
SELECT 
    (SELECT COUNT(*) FROM player_kd) as total_registered_players,
    (SELECT SUM(kills) FROM player_kd) as total_kills,
    (SELECT SUM(deaths) FROM player_kd) as total_deaths,
    (SELECT AVG(kd_ratio) FROM player_kd WHERE kills > 0) as average_kd_ratio,
    (SELECT MAX(kd_ratio) FROM player_kd) as highest_kd_ratio,
    (SELECT MAX(kills) FROM player_kd) as most_kills,
    (SELECT identifier FROM player_kd ORDER BY kd_ratio DESC LIMIT 1) as best_kd_player;

-- Örnek sorgular:
-- En iyi 10 oyuncu:
-- SELECT * FROM top_kd_players LIMIT 10;

-- Belirli bir oyuncunun istatistikleri:
-- SELECT * FROM player_kd WHERE identifier = 'steam:xxxxxxxxx';

-- Genel sunucu istatistikleri:
-- SELECT * FROM kd_overview;

-- Son 24 saatteki aktivite:
-- SELECT COUNT(*) as recent_updates FROM player_kd WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR);
