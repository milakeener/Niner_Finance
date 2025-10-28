-- Income Categories Table
DROP TABLE IF EXISTS income_category;
CREATE TABLE income_category (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    FOREIGN KEY (created_by) REFERENCES user (id),
    UNIQUE(name)
);

-- Create default income categories
INSERT INTO income_category (name, description, created_by) VALUES
('Salary', 'Regular employment income', 1),
('Freelance', 'Income from freelance work', 1),
('Investment', 'Income from investments', 1),
('Business', 'Business income', 1),
('Rental', 'Rental property income', 1),
('Other', 'Other sources of income', 1);

-- Income Table
DROP TABLE IF EXISTS income;
CREATE TABLE income (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    source VARCHAR(100) NOT NULL,
    description TEXT,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_recurring BOOLEAN NOT NULL DEFAULT 0,
    recurrence_period VARCHAR(20) CHECK (
        recurrence_period IS NULL OR 
        recurrence_period IN ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'annually')
    ),
    next_recurrence_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by INTEGER NOT NULL,
    updated_by INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES user (id),
    FOREIGN KEY (category_id) REFERENCES income_category (id),
    FOREIGN KEY (created_by) REFERENCES user (id),
    FOREIGN KEY (updated_by) REFERENCES user (id)
);

-- Create indexes for better query performance
CREATE INDEX idx_income_user_date ON income(user_id, date);
CREATE INDEX idx_income_category ON income(category_id);
CREATE INDEX idx_income_recurring ON income(is_recurring, next_recurrence_date) 
    WHERE is_recurring = 1;
CREATE INDEX idx_income_source ON income(source);

-- Create trigger to update the updated_at timestamp
CREATE TRIGGER income_update_timestamp
AFTER UPDATE ON income
BEGIN
    UPDATE income 
    SET updated_at = CURRENT_TIMESTAMP,
        updated_by = NEW.updated_by
    WHERE id = NEW.id;
END;

-- Create trigger to validate recurrence data
CREATE TRIGGER income_recurrence_validation
BEFORE INSERT ON income
BEGIN
    SELECT
        CASE
            WHEN NEW.is_recurring = 1 AND NEW.recurrence_period IS NULL
            THEN RAISE(ABORT, 'Recurrence period is required for recurring income')
            WHEN NEW.is_recurring = 1 AND NEW.next_recurrence_date IS NULL
            THEN RAISE(ABORT, 'Next recurrence date is required for recurring income')
            WHEN NEW.is_recurring = 0 AND (NEW.recurrence_period IS NOT NULL OR NEW.next_recurrence_date IS NOT NULL)
            THEN RAISE(ABORT, 'Recurrence fields must be NULL for non-recurring income')
        END;
END;

-- Create view for active income records
CREATE VIEW v_active_income AS
SELECT 
    i.id,
    i.user_id,
    u.username,
    i.category_id,
    ic.name as category_name,
    i.amount,
    i.source,
    i.description,
    i.date,
    i.is_recurring,
    i.recurrence_period,
    i.next_recurrence_date,
    i.created_at,
    i.updated_at,
    creator.username as created_by_username,
    updater.username as updated_by_username
FROM income i
JOIN user u ON i.user_id = u.id
JOIN income_category ic ON i.category_id = ic.id
JOIN user creator ON i.created_by = creator.id
LEFT JOIN user updater ON i.updated_by = updater.id
WHERE i.is_active = 1 AND ic.is_active = 1;
