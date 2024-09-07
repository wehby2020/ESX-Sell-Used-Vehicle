CREATE TABLE `vehicles_for_sale` (
  `id` int(11) NOT NULL,
  `seller` varchar(50) NOT NULL,
  `vehicleProps` longtext NOT NULL,
  `price` int(11) NOT NULL DEFAULT 0,
  `description` varchar(200) DEFAULT NULL,
  `plate` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

ALTER TABLE `vehicles_for_sale`
  ADD PRIMARY KEY (`id`);


ALTER TABLE `vehicles_for_salew`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

CREATE TABLE IF NOT EXISTS `carmileages` (
  `plate` text DEFAULT NULL,
  `mileage` text DEFAULT NULL
);


