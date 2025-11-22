# ?? Perico Air Garage

Store and retrieve planes at the Cayo Perico hangar with SQL persistence.

## Installation
1. Drop `perico_airgarage` into your `resources` folder.
2. Add `ensure perico_airgarage` to `server.cfg`.
3. Create the table in your database:

```sql
CREATE TABLE IF NOT EXISTS perico_planes (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizenid VARCHAR(64) NOT NULL,
  plate VARCHAR(15) NOT NULL,
  model VARCHAR(64) NOT NULL,
  props LONGTEXT NOT NULL,
  is_stored TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY unique_plate (plate),
  KEY idx_citizenid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
