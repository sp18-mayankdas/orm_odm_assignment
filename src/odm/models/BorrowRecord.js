const mongoose = require('mongoose');

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
      default: Date.now()
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

const BorrowRecord = mongoose.model('BorrowRecord', borrowRecordSchema);
module.exports = BorrowRecord;
