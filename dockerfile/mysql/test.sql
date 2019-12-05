
-- 创建数据库
CREATE DATABASE codelieche DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 选择数据库
use codelieche;

-- 创建表
CREATE TABLE users (
	`id` INT PRIMARY KEY AUTO_INCREMENT,
	`name` VARCHAR(40) NOT NULL COMMENT "用户名",
	`age` INT UNSIGNED NOT NULL COMMENT "年龄",
	`email` VARCHAR(100) COMMENT "邮箱"
) ENGINE = INNODB COMMENT = "用户表";

-- 插入数据
INSERT INTO users (`name`, `age`, `email`) VALUES
 ("Tome", 18, "tome@example.com"),
 ("Jim", 19, "jim@example.com"),
 ("admin", 26, "admin@example.com"),
 ("Tome2", 18, "tome2@example.com"),
 ("Jim2", 19, "jim2@example.com");

