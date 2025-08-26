# Task 1: Member and Profile Management (One-to-One)

// Create or update profile

// Create Member Profile
async function create(req, res) {
  try {
    const memberId = req.user.id;
  
    const existingProfile = await MemberProfile.findOne({ member: memberId });
    if (existingProfile) {
      return res.status(400).json({ success: false, message: 'Profile already exists for this member.' });
    }

    const profileData = {
      member: memberId,
      address: req.body.address,
      phone: req.body.phone,
    };

    const profile = await MemberProfile.create(profileData);

    res.status(201).json({ success: true, profile });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || err });
  }
}

// Update Member Profile
async function update(req, res) {
  try {
    const memberId = req.user._id;
    const profileData = {
      address: req.body.address,
      phone: req.body.phone,
    };

    const profile = await MemberProfile.findOneAndUpdate(
      { member: memberId },
      profileData,
      { new: true, runValidators: true }
    );

    if (!profile) {
      return res.status(404).json({ success: false, message: 'Profile not found.' });
    }

    res.status(200).json({ success: true, profile });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || err });
  }
}
- Ensure the same profile cannot be assigned to multiple members.

## Solution: 

member_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Member',
    unique: true, 
    }

# Task 2: Book Management

- Allow adding, updating, and deleting books.
- Ensure that each book has a unique ISBN.
- Prevent book deletion if any active BorrowRecord exists for that book.

## Solution:

book_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Book',
      required: true
    }

ISBN: {
    type: String,
    required: [true, 'ISBN is required'],
    unique: true,
    trim: true,
    }


const isBorrowedActive = await borrowRecord.exists({book:book_id , status:'Borrowed'});
if(isBorrowedActive){
    throw new Error('Cannot delete book with active borrow records');
}

# Task 3: Borrow Record Management (One-to-Many)

1. Allow members to borrow books
2. Ensure that the availableCopies of the book decreases when a book is borrowed.
3. Allow returning books and update BorrowRecord accordingly
4. When a book is returned, the availableCopies should increase.
5. If a book is returned after 14 days of borrowing, mark the status as "Overdue".
6. Only members with an "Active" membership can borrow books.

## Solution :

const borrowRecordSchema = new mongoose.Schema(
  {
    member_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Member',
      required: true
    },
    book_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Book',
      required: true
    },
    borrowDate: {
      type: Date,
      required: true,
      default: Date.now // auto-set on creation
    },
    returnDate: {
      type: Date,
      required: false
    },
    status: {
      type: String,
      enum: ['Borrowed', 'Returned', 'Overdue'],
      default: 'Borrowed',
      required: true
    }
  },
  {
    timestamps: true,
    collection: 'borrowRecord',
    toJSON: {
      transform(doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      }
    },
    toObject: {
      transform(doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      }
    }
  }
);

async function borrowBook(memberId, bookId) {
  const member = await Member.findById(memberId);
  if (!member || member.status !== 'Active') {
    throw new Error('Member not found or not active');
  }

  // Check if book exists and has available copies
  const book = await Book.findById(bookId);
  if (!book || book.availableCopies < 1) {
    throw new Error('Book not available');
  }

  // Create borrow record
  const borrowRecord = new BorrowRecord({
    member_id: memberId,
    book_id: bookId,
    borrowDate: new Date(),
    status: 'Borrowed'
  });
  await borrowRecord.save();

  // Decrease availableCopies
  book.availableCopies = book.availableCopies - 1;
  await book.save();

  return borrowRecord;
}

async function returnBook(borrowRecordId) {

  const record = await BorrowRecord.findById(borrowRecordId);
  if (!record || record.status !== 'Borrowed') {
    throw new Error('Borrow record not found or already returned');
  }

  // Set return date
  record.returnDate = new Date();

  // Check if overdue (after 14 days)
  const borrowTime = record.borrowDate;
  const now = new Date();
  const diffDays = Math.floor((now - borrowTime) / (1000 * 60 * 60 * 24));
  if (diffDays > 14) {
    record.status = 'Overdue';
  } else {
    record.status = 'Returned';
  }
  await record.save();

  // Increase availableCopies
  const book = await Book.findById(record.book_id);
  if (book) {
    book.availableCopies = book.availableCopies + 1;
    await book.save();
  }

  return record;
}

# Task 4: Validations

- Email in Member and Profile must be unique.
- Phone number in Profile must be unique.
- ISBN in Book must be unique.
- Price of a book cannot be negative.
- availableCopies of a book cannot be negative.
- A member cannot borrow the same book again until they return it.

## Soltuions: 

    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/,
        'Please enter a valid email address'
      ]
    }


phone: {
      type: String,
      required: [true, 'Phone number is required'],
      unique: true,
      trim: true,
      minlength: [7, 'Phone number seems too short'],
      maxlength: [20, 'Phone number seems too long'],
      match: [
        /^[0-9+\-\s()]*$/,
        'Please provide a valid phone number'
      ]
    }


ISBN: {
      type: String,
      required: [true, 'ISBN is required'],
      unique: true,
      trim: true,
    }


price: {
      type: Number,
      required: [true, 'Price is required'],
      min: [0, 'Price cannot be negative']
    }


availableCopies: {
      type: Number,
      required: [true, 'Available copies is required'],
      min: [0, 'Available copies cannot be negative']
    }


const activeBorrow = await BorrowRecord.findOne({
  member: member_id,
  book: book_id,
  status: 'Borrowed'
});
if (activeBorrow) {
  throw new Error('You cannot borrow the same book again until you return it.');
}

# Task 5: Hooks and Middleware

## Use Mongoose Hooks:

- Auto-set membershipDate for new members.
- Auto-set borrowDate for new BorrowRecord.
- Update availableCopies of a book using hooks when a book is borrowed or returned.
- Auto-check and update the status of BorrowRecord as "Overdue" if not returned in 14 days.

## Solutions: 

memberSchema.pre('save', function(next) {
  if (this.isNew && !this.membershipDate) {
    this.membershipDate = new Date();
  }
  next();
});


borrowRecordSchema.pre('save', function(next) {
  if (this.isNew && !this.borrowDate) {
    this.borrowDate = new Date();
  }
  next();
});


borrowRecordSchema.pre('save', async function(next) {
  if (this.isNew && this.status === 'Borrowed') {
    const Book = mongoose.model('Book');
    const book = await Book.findById(this.book);

    if (book.availableCopies <= 0) {
      return next(new Error('No available copies of the book to borrow.'));
    }

    book.availableCopies -= 1;
    await book.save();
  }
  next();
});


borrowRecordSchema.pre('save', function(next) {
  if (this.isModified('returnDate') && this.returnDate && this.status === 'Borrowed') {
    const borrowed = this.borrowDate;
    const returned = this.returnDate;
    const days = (returned - borrowed) / (1000 * 60 * 60 * 24);
    if (days > 14) {
      this.status = 'Overdue';
    } else {
      this.status = 'Returned';
    }
  }
  next();
});



## Use Express Middleware for:

- Error handling and validation.

## Document based middleware

bookSchema.pre('validate', function(next) {
  if (this.availableCopies < 0) {
    this.invalidate('availableCopies', 'Available copies cannot be negative');
  }
  if (this.price < 0) {
    this.invalidate('price', 'Price cannot be negative');
  }
  next();
});

// Post-save middleware for logging
bookSchema.post('save', function(doc, next) {
  console.log(`Book saved: ${doc.title} (${doc.ISBN})`);
  next();
});

## Query Middleware:

bookSchema.pre('findOneAndDelete', async function(next) {
  const docToDelete = await this.model.findOne(this.getQuery());
  const BorrowRecord = mongoose.model('BorrowRecord');
  const activeBorrow = await BorrowRecord.findOne({
    book: docToDelete._id,
    status: 'Borrowed'
  });
  if (activeBorrow) {
    return next(new Error('Cannot delete book with active borrow records.'));
  }
  next();
});
