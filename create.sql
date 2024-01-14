DROP TABLE IF EXISTS `log`;
CREATE TABLE `log` (
  `created` timestamp NULL DEFAULT NULL,
  `int_id` char(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `str` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
ALTER TABLE `log` ADD KEY `address` (`address`);

DROP TABLE IF EXISTS `message`;
CREATE TABLE `message` (
  `created` timestamp NOT NULL,
  `id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `int_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `str` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` BOOLEAN DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
ALTER TABLE `message`
  ADD PRIMARY KEY (`id`),
  ADD KEY `message_created_idx` (`created`),
  ADD KEY `message_int_id_idx` (`int_id`);
