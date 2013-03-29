#
# Add this to the etherpad-lite database in order to track timestamps of the last day that a
# pad was modified. We use this to destroy old pads.
#

#
# Create a table 'pad_timestamps' that just maps pad name to timestamp:
#

DROP INDEX pad_name ON pad_timestamps;
DROP TABLE pad_timestamps;

CREATE TABLE pad_timestamps (pad VARCHAR(100), time DATE);
CREATE UNIQUE INDEX pad_name ON pad_timestamps (pad);

#
# Set a trigger on table 'store' that inserts a row into pad_timestamps
# whenever a pad is modified (ie, new key is inserted of the form
# "pad:<padid>:revs:<n>" where <padid> is the name of the pad and <n> is the
# revision number).
#
# Because mysql doesn't bother updating a record when the values don't change,
# this trigger should be relatively efficient. The pad timestamp column is of type
# date, so at most the pad_timestamp table will have one update per pad per day.
#

DROP TRIGGER add_pad_timestamp;
DELIMITER $$
CREATE TRIGGER `add_pad_timestamp`
  AFTER INSERT ON `store` FOR EACH ROW
  BEGIN
    IF POSITION('pad:' IN NEW.key) = 1 AND POSITION(':revs:' IN NEW.key) THEN
      SET @padname = SUBSTR(SUBSTRING_INDEX(NEW.key, ':', 2),5);
      SET @padtime = DATE(NOW());
      INSERT INTO pad_timestamps(pad, time) VALUES (@padname, @padtime) ON DUPLICATE KEY UPDATE time = @padtime;
    END IF;
  END
$$
DELIMITER ;

