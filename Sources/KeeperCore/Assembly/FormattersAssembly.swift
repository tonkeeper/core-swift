import Foundation

final class FormattersAssembly {
  var amountFormatter: AmountFormatter {
    AmountFormatter(bigIntFormatter: bigIntAmountFormatter)
  }
  
  var bigIntAmountFormatter: BigIntAmountFormatter {
    BigIntAmountFormatter()
  }
  
  var shortNumberFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.groupingSeparator = " "
    formatter.groupingSize = 3
    formatter.usesGroupingSeparator = true
    formatter.decimalSeparator = Locale.current.decimalSeparator
    formatter.maximumFractionDigits = 2
    return formatter
  }
  
  var decimalAmountFormatter: DecimalAmountFormatter {
    DecimalAmountFormatter(numberFormatter: shortNumberFormatter)
  }
  
  var dateFormatter: DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale.init(identifier: "EN")
    return dateFormatter
  }
}
