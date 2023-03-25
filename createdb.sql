connect to project; 

create variable today date;
create variable fine_daily_rate_in_cents integer default 5;

create table Category(
	category_name char(10) not null,
	checkout_period integer not null,
	max_books_out integer not null,
	primary key (category_name),
	constraint checkout_period_nonnegative check (checkout_period >= 0),
	constraint max_books_out_nonnegative check (max_books_out >= 0) 
);

create table Borrower(
	borrower_id char(10) not null,
	last_name char(20) not null,
	first_name char(20) not null,
	category_name char(10) not null,
	primary key (borrower_id),
	foreign key (category_name) references Category(category_name)
);

create table Borrower_phone(
    borrower_id char(10) not null,
    phone char(20) not null,
	primary key (borrower_id, phone),
	foreign key (borrower_id) references Borrower(borrower_id)
);

create table Book_info(
	call_number char(20) not null,
	title char(50) not null,
	format char(2) not null,
	primary key (call_number)
);

-- The code supplied below for bar_code will cause it to be generated
-- automatically when a new Book is added to the database

create table Book(
	call_number char(20) not null,
	copy_number smallint not null,
	bar_code integer
		generated always as identity (start with 1),
	primary key (call_number, copy_number),
	unique (bar_code),
	foreign key (call_number) references Book_info(call_number)
);

create table Book_author(
	call_number char(20) not null,
	author_name char(20) not null,
	primary key (call_number, author_name),
	foreign key (call_number) references Book_info(call_number)
);

create table Book_keyword(
    call_number char(20) not null,
    keyword varchar(20) not null,
	primary key (call_number, keyword),
	foreign key (call_number) references Book_info(call_number)
);

create table Checked_out(
	call_number char(20) not null,
	copy_number smallint not null,
	borrower_id char(10) not null,
	date_due date not null,
	primary key (call_number, copy_number),
	foreign key (call_number, copy_number) references Book(call_number, copy_number),
	foreign key (borrower_id) references Borrower(borrower_id)
);

create table Fine(
	borrower_id char(10) not null,
	title char(50) not null,
	date_due date not null,
	date_returned date not null,
	amount numeric(10,2) not null,
	primary key (borrower_id, title, date_due),
	foreign key (borrower_id) references Borrower(borrower_id)
);

-- This trigger will delete all other information on book if last
-- copy is deleted

create trigger last_book_trigger
	after delete on Book
	referencing old as o
	for each row 
	when ((select count(*) 
			from book 
			where call_number = o.call_number) 
		= 0)
		delete from Book_info
			where call_number = o.call_number;
			
-- This trigger will prevent an attempt to renew a book that is overdue

create trigger cant_renew_overdue_trigger
	before update on Checked_out
	referencing old as o
	for each row
	when (o.date_due < today)
		 signal sqlstate '70000'
		 set message_text = 'CANT_RENEW_OVERDUE';

-- Code needed to create other triggers should be added here
