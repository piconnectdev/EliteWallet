String formatAmount(String amount) {
  while (amount.endsWith('0')) {
    amount = amount.substring(0, amount.length - 1);
  }
  if ((!amount.contains('.'))&&(!amount.contains(','))) {
    return amount + '.00';
  } else if ((amount.endsWith('.'))||(amount.endsWith(','))) {
    return amount + '00';
  }
  return amount;
}