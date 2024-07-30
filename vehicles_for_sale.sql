CREATE TABLE `vehicles_for_sale` (
  `id` int(11) NOT NULL,
  `seller` varchar(50) NOT NULL,
  `vehicleProps` longtext NOT NULL,
  `price` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

ALTER TABLE `vehicles_for_sale` MODIFY COLUMN `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE `vehicles_for_sale` ADD COLUMN `plate` varchar(15) NOT NULL;

CREATE TABLE IF NOT EXISTS `carmileages` (
  `plate` text DEFAULT NULL,
  `mileage` text DEFAULT NULL
);


