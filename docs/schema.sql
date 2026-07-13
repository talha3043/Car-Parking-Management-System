create database ParkSlotMasterDB
use ParkSlotMasterDB

Create Table Vehicles
(
  LicenseNo varchar(20) unique not null ,
  Category varchar(10) check ( Category IN ('Sedan','SUV','Compact')) null ,
    Constraint PrimaryKey_Vehicles Primary Key (LicenseNo) 
);

Create Table Users
(
  UserName varchar(100) not null ,
  UserCNIC varchar(20) not null ,
  UserPhoneNo varchar(15) unique not null ,
    Constraint PrimaryKey_Users Primary Key (UserCNIC)
);

Create Table ParkingSlots 
(
  SlotNumber int not null ,  
  [Status] varchar(10) Check ( [Status] IN ('Available', 'Occupied')) not null default 'Available' ,
    Constraint PrimaryKey_ParkingSlots Primary Key (SlotNumber)
);

Create Table Reservation_Details
(
  ReservationId int Identity(1,1) not null ,
  LicenseNo varchar(20) null ,
  SlotNumber int not null ,
  UserCNIC  varchar(20) not null 
  Constraint ForeignKey_UserCNIC Foreign Key (UserCNIC) References Users(UserCNIC)
  on delete no action on update no action ,
  PaymentStatus varchar(10) Check (PaymentStatus IN ('Paid', 'Unpaid'))
     not null default 'Unpaid' ,
    Constraint ForeignKey_LicenseNo_R Foreign Key (LicenseNo) References Vehicles(LicenseNo) 
        on delete no action on update no action ,
    Constraint ForeignKey_SlotNumber Foreign Key (SlotNumber) References ParkingSlots(SlotNumber)
        on delete no action on update no action ,
    Constraint PrimaryKey_Reservation_Details Primary Key (ReservationId)
);

Create table Reservation_TimeInterval_Record
(
   ReservationId int not null 
   Constraint ForeignKey_ReservaytionID_TimeInterval_Record Foreign Key (ReservationId) References Reservation_Details(ReservationId),
   ArrivalTime datetime default getDate() ,
   DepartureTime datetime null ,
    Constraint PK_Reservation_TimeInterval_Record Primary Key (ReservationId)
);

Create Table Reservations_Charges
(
   ReservationId int not null 
   Constraint ForeignKey_ReservaytionID_Charges Foreign Key (ReservationId) References Reservation_Details(ReservationId)
        on delete no action on update no action ,
   ParkingFee Decimal(10,2) null ,
   Fine Decimal(10,2) null ,
   Constraint PK_Reservations_Charges Primary Key (ReservationId)
);

Create table Admin_Logins (
  AdminCNIC varchar(20) not null,
  AdminName varchar(100) not null,
  Password varchar(10) unique not null,
  Constraint PK_AdminLogins Primary key (AdminCNIC)
);

Create table Admins_Details (
  AdminCNIC varchar(20) not null,
  AdminPhoneNo varchar(15) unique not null,
  AdminAddress text NULL,
  Constraint FK_AdminLogin_Admin foreign key (AdminCNIC) references Admin_Logins(AdminCNIC),
  constraint PK_Admins Primary key (AdminCNIC)
);

Create Table Vehicle_Details
(
  HistoryId int identity(1,1) not null,
  ReservationId int not null,
  LicenseNo varchar(20) not null,
  SlotNumber int not null,
  Constraint PK_Vehicle_Details Primary Key (HistoryId),
);

Create Table History_Records
(
  HistoryId int  not null,
  ArrivalTime datetime default getDate(),
  DepartureTime datetime null,
  Constraint PK_History_Records Primary Key (HistoryId),
  Constraint FK_History_Record Foreign Key (HistoryId) References Vehicle_Details(HistoryId),
);

Create table Charges_History
(
  HistoryId int not null,
  ParkingFee decimal(10,2) null,
  Fine decimal(10,2) null,
  Constraint PK_Charges_History Primary Key (HistoryId),
  Constraint FK_Charges_History Foreign Key (HistoryId) References Vehicle_Details(HistoryId)
)

Create Table User_History
(
  HistoryId int not null,
  UserCNIC varchar(20) not null,
  Constraint PK_User_History Primary Key (HistoryId),
  Constraint FK_User_History Foreign Key (HistoryId) References Vehicle_Details(HistoryId)
);