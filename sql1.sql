DROP TABLE IF EXISTS `temp`;
CREATE TABLE `temp` (
  `raw` varchar(1024) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `created` timestamp NULL DEFAULT NULL,
  `int_id` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `str` varchar(1024) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `flag` varchar(2) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


LOAD DATA LOCAL INFILE  "C:/Strawberry/test/out" INTO TABLE `temp` FIELDS TERMINATED BY "{=@|=|@=}" LINES TERMINATED BY "\n";


UPDATE `temp` SET `created`=LEFT(`raw`,19), `int_id`=MID(`raw`,21,16), `flag`=MID(`raw`,38,2), `str`= MID(`raw`,21,1024);


DROP TABLE IF EXISTS `log`;
CREATE TABLE `log` (
  `created` timestamp NULL DEFAULT NULL,
  `int_id` char(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `str` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


INSERT INTO `log` SELECT `created`, `int_id`, `str`, IF(`flag`='=>' OR `flag`='->' OR `flag`='**' OR `flag`='==', MID(`str`,21,LOCATE(' ',MID(`str`,21,1000))-1), '') `address` FROM `temp` WHERE `flag`!='<=';

ALTER TABLE `log` ADD KEY `address` (`address`);

UPDATE `log` SET `address`=LEFT(`address`,LENGTH(`address`)-1) WHERE `address`!=':blackhole:' AND `address` LIKE '%:'


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

INSERT IGNORE INTO `message` SELECT `created`, IF(LOCATE(' id=',`str`),MID(`str`,LOCATE(' id=',`str`)+4,1024),''),  `int_id`, `str`, NULL FROM `temp` WHERE `flag`='<=';

DELETE FROM `message` WHERE `id`='' LIMIT 1;
