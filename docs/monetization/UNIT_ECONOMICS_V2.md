# Unit Economics v2

## Формула

```
LTV = ARPU_sub + ARPU_iap
ARPU_sub = SubPrice × RetentionMonths × SubConversion × (1 - PlatformFee)
ARPU_iap = IAPConversion × AvgIAPSpend × (1 - PlatformFee)
Прибыль = LTV × (1 - AuthorShare) - CAC - VariableCost
```

## Реалистичный пример

| Параметр | Значение |
|----------|----------|
| Sub price | $5.99 |
| Retention | 4 мес |
| Sub conversion | 2% |
| IAP conversion | 8% |
| Avg IAP spend | $6 |
| Platform fee | 30% |
| Author share | 40% |

- ARPU_sub ≈ $0.48
- ARPU_iap ≈ $0.34
- **Total ARPU ≈ $0.82**

## Расхождения со старой моделью (только sub $3)

- CAC $0.05–0.20 занижен для paid UA
- Choices VIP = $14.99; наш старт $4.99–6.99
- Без IAP экономика хрупкая на пессимистичном сценарии

Notion: [Unit экономика v2](https://app.notion.com/p/3817075eda5781619c4cd0d4a25c5a59)
