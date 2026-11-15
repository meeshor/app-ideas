# Weryfikacja wartości odżywczych z USDA

Plik generuje `npm run data` (scripts/usda-apply.ts) — nie edytuj ręcznie. Wartości na 100 g.
Źródło: USDA FoodData Central, SR Legacy (kwiecień 2018), powiązania w `data-src/usda-map.ts`.
„≠” oznacza różnicę powyżej 15% kcal albo 3 g któregokolwiek makro.
Węglowodany ogółem, z błonnikiem (jak w USDA); wyjątek: kakao w proszku.

## Ten sam produkt — wartości z USDA, `verified: true` (120)

Kolumna „Przed” to wartości z `data-src/foods.ts`; w aplikacji są już wartości USDA.
Istotnie poprawionych: **18**.

| Produkt | Przed (kcal / W / B / T) | USDA | | Pozycja USDA | Uwagi |
|---|---|---|---|---|---|
| bułka pszenna | 290 / 57 / 9 / 2.5 | 293 / 52.7 / 9.9 / 4.3 | **≠** | [175031](https://fdc.nal.usda.gov/food-details/175031/nutrients) Rolls, hard (includes kaiser) | kajzerka |
| chleb pełnoziarnisty | 240 / 42 / 9 / 3.5 | 252 / 42.7 / 12.5 / 3.5 | **≠** | [172688](https://fdc.nal.usda.gov/food-details/172688/nutrients) Bread, whole-wheat, commercially prepared |  |
| chleb tostowy | 265 / 48 / 8 / 4 | 266 / 49.4 / 8.9 / 3.3 | ≈ | [174924](https://fdc.nal.usda.gov/food-details/174924/nutrients) Bread, white, commercially prepared (includes soft bread crumbs) | biały chleb kanapkowy |
| bagietka | 270 / 55 / 9 / 1.5 | 272 / 51.9 / 10.8 / 2.4 | **≠** | [172675](https://fdc.nal.usda.gov/food-details/172675/nutrients) Bread, french or vienna (includes sourdough) |  |
| croissant | 406 / 45 / 8 / 21 | 406 / 45.8 / 8.2 / 21 | ≈ | [174987](https://fdc.nal.usda.gov/food-details/174987/nutrients) Croissants, butter |  |
| wafel ryżowy | 390 / 81 / 8 / 3 | 387 / 81.5 / 8.2 / 2.8 | ≈ | [170250](https://fdc.nal.usda.gov/food-details/170250/nutrients) Snacks, rice cakes, brown rice, plain, unsalted |  |
| tortilla | 300 / 50 / 8 / 7 | 306 / 49.4 / 8.2 / 8 | ≈ | [175037](https://fdc.nal.usda.gov/food-details/175037/nutrients) Tortillas, ready-to-bake or -fry, flour, refrigerated |  |
| masło | 735 / 0.7 / 0.7 / 82.5 | 717 / 0.1 / 0.9 / 81.1 | ≈ | [173430](https://fdc.nal.usda.gov/food-details/173430/nutrients) Butter, without salt |  |
| mleko | 50 / 4.8 / 3.4 / 2 | 50 / 4.8 / 3.3 / 2 | ≈ | [172205](https://fdc.nal.usda.gov/food-details/172205/nutrients) Milk, reduced fat, fluid, 2% milkfat, without added vitamin A and vitamin D | 2% |
| mleko pełne | 61 / 4.7 / 3.2 / 3.2 | 61 / 4.8 / 3.2 / 3.3 | ≈ | [172217](https://fdc.nal.usda.gov/food-details/172217/nutrients) Milk, whole, 3.25% milkfat, without added vitamin A and vitamin D | 3,25% |
| mleko chude | 36 / 4.9 / 3.4 / 0.5 | 35 / 4.9 / 3.4 / 0.2 | ≈ | [173432](https://fdc.nal.usda.gov/food-details/173432/nutrients) Milk, nonfat, fluid, without added vitamin A and vitamin D (fat free or skim) |  |
| mleko sojowe | 40 / 2.5 / 3.3 / 1.8 | 43 / 4.9 / 2.6 / 1.5 | ≈ | [172456](https://fdc.nal.usda.gov/food-details/172456/nutrients) Soymilk, original and vanilla, with added calcium, vitamins A and D |  |
| śmietana 12% | 135 / 3.9 / 2.7 / 12 | 135 / 4.3 / 2.9 / 12 | ≈ | [171256](https://fdc.nal.usda.gov/food-details/171256/nutrients) Cream, sour, reduced fat, cultured |  |
| śmietana 30% | 290 / 3.2 / 2.2 / 30 | 292 / 3 / 2.2 / 30.9 | ≈ | [170858](https://fdc.nal.usda.gov/food-details/170858/nutrients) Cream, fluid, light whipping |  |
| ser żółty | 356 / 2.2 / 25 / 27 | 356 / 2.2 / 24.9 / 27.4 | ≈ | [171241](https://fdc.nal.usda.gov/food-details/171241/nutrients) Cheese, gouda | gouda |
| parmezan | 392 / 3 / 35 / 28 | 392 / 3.2 / 35.8 / 25 | ≈ | [170848](https://fdc.nal.usda.gov/food-details/170848/nutrients) Cheese, parmesan, hard |  |
| ser feta | 265 / 4 / 14 / 21 | 265 / 3.9 / 14.2 / 21.5 | ≈ | [173420](https://fdc.nal.usda.gov/food-details/173420/nutrients) Cheese, feta |  |
| ser pleśniowy | 300 / 0.5 / 20 / 24 | 300 / 0.5 / 19.8 / 24.3 | ≈ | [172178](https://fdc.nal.usda.gov/food-details/172178/nutrients) Cheese, camembert | camembert |
| jajko | 140 / 0.7 / 12.5 / 9.7 | 143 / 0.7 / 12.6 / 9.5 | ≈ | [171287](https://fdc.nal.usda.gov/food-details/171287/nutrients) Egg, whole, raw, fresh |  |
| parówka | 260 / 2 / 11 / 23 | 269 / 0.3 / 12.8 / 23.7 | ≈ | [172964](https://fdc.nal.usda.gov/food-details/172964/nutrients) Frankfurter, pork | frankfurterka wieprzowa |
| salami | 430 / 1 / 22 / 37 | 378 / 0.7 / 21.1 / 31.7 | **≠** | [174582](https://fdc.nal.usda.gov/food-details/174582/nutrients) Salami, dry or hard, pork, beef |  |
| boczek | 400 / 0.5 / 15 / 38 | 393 / 0 / 13.7 / 37.1 | ≈ | [168277](https://fdc.nal.usda.gov/food-details/168277/nutrients) Pork, cured, bacon, unprepared | surowy wędzony |
| pierś z kurczaka | 165 / 0 / 31 / 3.6 | 165 / 0 / 31 / 3.6 | ≈ | [171477](https://fdc.nal.usda.gov/food-details/171477/nutrients) Chicken, broilers or fryers, breast, meat only, cooked, roasted | pieczona, bez skóry |
| udko z kurczaka | 215 / 0 / 24 / 13 | 232 / 0 / 23.3 / 14.7 | ≈ | [173625](https://fdc.nal.usda.gov/food-details/173625/nutrients) Chicken, broilers or fryers, thigh, meat and skin, cooked, roasted | pieczone, ze skórą |
| pierś z indyka | 135 / 0 / 29 / 2 | 136 / 0 / 29.5 / 2 | ≈ | [174516](https://fdc.nal.usda.gov/food-details/174516/nutrients) Turkey, retail parts, breast, meat only, cooked, roasted | pieczona |
| schab pieczony | 180 / 0 / 28 / 7 | 173 / 0 / 27.6 / 6.1 | ≈ | [168253](https://fdc.nal.usda.gov/food-details/168253/nutrients) Pork, fresh, loin, top loin (chops), boneless, separable lean only, cooked, broiled | chudy, z grilla |
| karkówka | 250 / 0 / 22 / 18 | 259 / 0 / 25.6 / 16.6 | **≠** | [167851](https://fdc.nal.usda.gov/food-details/167851/nutrients) Pork, fresh, shoulder, blade, boston (steaks), separable lean and fat, cooked, broiled |  |
| wołowina | 200 / 0 / 28 / 10 | 204 / 0 / 30.7 / 9 | ≈ | [169531](https://fdc.nal.usda.gov/food-details/169531/nutrients) Beef, round, top round steak, separable lean and fat, trimmed to 1/8"" fat, all grades, cooked, broiled | zrazowa górna, pieczona |
| łosoś | 206 / 0 / 22 / 13 | 206 / 0 / 22.1 / 12.4 | ≈ | [175168](https://fdc.nal.usda.gov/food-details/175168/nutrients) Fish, salmon, Atlantic, farmed, cooked, dry heat | hodowlany, pieczony |
| dorsz | 105 / 0 / 23 / 0.9 | 105 / 0 / 22.8 / 0.9 | ≈ | [171956](https://fdc.nal.usda.gov/food-details/171956/nutrients) Fish, cod, Atlantic, cooked, dry heat |  |
| tuńczyk w sosie własnym | 110 / 0 / 25 / 1 | 116 / 0 / 25.5 / 0.8 | ≈ | [171986](https://fdc.nal.usda.gov/food-details/171986/nutrients) Fish, tuna, light, canned in water, without salt, drained solids |  |
| ryż biały | 130 / 28 / 2.7 / 0.3 | 130 / 28.2 / 2.7 / 0.3 | ≈ | [168878](https://fdc.nal.usda.gov/food-details/168878/nutrients) Rice, white, long-grain, regular, enriched, cooked |  |
| ryż brązowy | 112 / 23 / 2.6 / 0.9 | 123 / 25.6 / 2.7 / 1 | ≈ | [169704](https://fdc.nal.usda.gov/food-details/169704/nutrients) Rice, brown, long-grain, cooked (Includes foods for USDA's Food Distribution Program) |  |
| makaron | 158 / 31 / 5.8 / 0.9 | 158 / 30.9 / 5.8 / 0.9 | ≈ | [169737](https://fdc.nal.usda.gov/food-details/169737/nutrients) Pasta, cooked, enriched, without added salt |  |
| makaron pełnoziarnisty | 124 / 25 / 5.3 / 0.5 | 149 / 30.1 / 6 / 1.7 | **≠** | [168910](https://fdc.nal.usda.gov/food-details/168910/nutrients) Pasta, whole-wheat, cooked (Includes foods for USDA's Food Distribution Program) |  |
| kasza gryczana | 92 / 20 / 3.4 / 0.6 | 92 / 19.9 / 3.4 / 0.6 | ≈ | [170686](https://fdc.nal.usda.gov/food-details/170686/nutrients) Buckwheat groats, roasted, cooked |  |
| kasza jaglana | 119 / 24 / 3.5 / 1 | 119 / 23.7 / 3.5 / 1 | ≈ | [168871](https://fdc.nal.usda.gov/food-details/168871/nutrients) Millet, cooked |  |
| kasza jęczmienna | 123 / 28 / 2.3 / 0.4 | 123 / 28.2 / 2.3 / 0.4 | ≈ | [170285](https://fdc.nal.usda.gov/food-details/170285/nutrients) Barley, pearled, cooked |  |
| kasza manna | 360 / 75 / 10 / 1 | 360 / 72.8 / 12.7 / 1.1 | ≈ | [169715](https://fdc.nal.usda.gov/food-details/169715/nutrients) Semolina, enriched | sucha |
| kuskus | 112 / 23 / 3.8 / 0.2 | 112 / 23.2 / 3.8 / 0.2 | ≈ | [169700](https://fdc.nal.usda.gov/food-details/169700/nutrients) Couscous, cooked |  |
| komosa ryżowa | 120 / 21 / 4.4 / 1.9 | 120 / 21.3 / 4.4 / 1.9 | ≈ | [168917](https://fdc.nal.usda.gov/food-details/168917/nutrients) Quinoa, cooked |  |
| płatki owsiane | 370 / 60 / 13 / 7 | 379 / 67.7 / 13.2 / 6.5 | **≠** | [173904](https://fdc.nal.usda.gov/food-details/173904/nutrients) Cereals, oats, regular and quick, not fortified, dry |  |
| płatki kukurydziane | 375 / 84 / 7 / 1 | 384 / 88 / 5.9 / 0.9 | **≠** | [174648](https://fdc.nal.usda.gov/food-details/174648/nutrients) Cereals ready-to-eat, RALSTON Corn Flakes |  |
| ziemniaki gotowane | 86 / 20 / 1.9 / 0.1 | 86 / 20 / 1.7 / 0.1 | ≈ | [170440](https://fdc.nal.usda.gov/food-details/170440/nutrients) Potatoes, boiled, cooked without skin, flesh, without salt |  |
| puree ziemniaczane | 106 / 15 / 2 / 4.2 | 113 / 16.8 / 1.9 / 4.2 | ≈ | [168555](https://fdc.nal.usda.gov/food-details/168555/nutrients) Potatoes, mashed, home-prepared, whole milk and butter added |  |
| frytki | 312 / 41 / 3.4 / 15 | 312 / 41.4 / 3.4 / 14.7 | ≈ | [170698](https://fdc.nal.usda.gov/food-details/170698/nutrients) Fast foods, potato, french fried in vegetable oil |  |
| placki ziemniaczane | 230 / 25 / 4 / 13 | 268 / 27.8 / 6.1 / 14.8 | ≈ | [170092](https://fdc.nal.usda.gov/food-details/170092/nutrients) Potato pancakes |  |
| pomidor | 18 / 3.9 / 0.9 / 0.2 | 18 / 3.9 / 0.9 / 0.2 | ≈ | [170457](https://fdc.nal.usda.gov/food-details/170457/nutrients) Tomatoes, red, ripe, raw, year round average |  |
| pomidorki koktajlowe | 18 / 3.9 / 0.9 / 0.2 | 18 / 3.9 / 0.9 / 0.2 | ≈ | [170457](https://fdc.nal.usda.gov/food-details/170457/nutrients) Tomatoes, red, ripe, raw, year round average |  |
| ogórek | 15 / 3.6 / 0.7 / 0.1 | 15 / 3.6 / 0.7 / 0.1 | ≈ | [168409](https://fdc.nal.usda.gov/food-details/168409/nutrients) Cucumber, with peel, raw |  |
| ogórek kiszony | 12 / 2.2 / 0.7 / 0.1 | 11 / 2.3 / 0.3 / 0.2 | ≈ | [169379](https://fdc.nal.usda.gov/food-details/169379/nutrients) Pickles, cucumber, sour |  |
| sałata | 15 / 2.9 / 1.4 / 0.2 | 15 / 2.9 / 1.4 / 0.2 | ≈ | [169249](https://fdc.nal.usda.gov/food-details/169249/nutrients) Lettuce, green leaf, raw |  |
| papryka | 31 / 6 / 1 / 0.3 | 26 / 6 / 1 / 0.3 | **≠** | [170108](https://fdc.nal.usda.gov/food-details/170108/nutrients) Peppers, sweet, red, raw |  |
| marchew | 41 / 9.6 / 0.9 / 0.2 | 41 / 9.6 / 0.9 / 0.2 | ≈ | [170393](https://fdc.nal.usda.gov/food-details/170393/nutrients) Carrots, raw |  |
| cebula | 40 / 9.3 / 1.1 / 0.1 | 40 / 9.3 / 1.1 / 0.1 | ≈ | [170000](https://fdc.nal.usda.gov/food-details/170000/nutrients) Onions, raw |  |
| czosnek | 149 / 33 / 6.4 / 0.5 | 149 / 33.1 / 6.4 / 0.5 | ≈ | [169230](https://fdc.nal.usda.gov/food-details/169230/nutrients) Garlic, raw |  |
| brokuł | 35 / 7 / 2.4 / 0.4 | 35 / 7.2 / 2.4 / 0.4 | ≈ | [169967](https://fdc.nal.usda.gov/food-details/169967/nutrients) Broccoli, cooked, boiled, drained, without salt | gotowany |
| kalafior | 25 / 5 / 1.9 / 0.3 | 23 / 4.1 / 1.8 / 0.5 | ≈ | [170397](https://fdc.nal.usda.gov/food-details/170397/nutrients) Cauliflower, cooked, boiled, drained, without salt | gotowany |
| kapusta kiszona | 21 / 4.3 / 1.1 / 0.1 | 19 / 4.3 / 0.9 / 0.1 | ≈ | [169279](https://fdc.nal.usda.gov/food-details/169279/nutrients) Sauerkraut, canned, solids and liquids |  |
| kapusta | 25 / 5.8 / 1.3 / 0.1 | 25 / 5.8 / 1.3 / 0.1 | ≈ | [169975](https://fdc.nal.usda.gov/food-details/169975/nutrients) Cabbage, raw |  |
| fasolka szparagowa | 35 / 7.9 / 1.9 / 0.3 | 35 / 7.9 / 1.9 / 0.3 | ≈ | [169141](https://fdc.nal.usda.gov/food-details/169141/nutrients) Beans, snap, green, cooked, boiled, drained, without salt |  |
| groszek zielony | 84 / 15.6 / 5.4 / 0.2 | 78 / 14.3 / 5.2 / 0.3 | ≈ | [170017](https://fdc.nal.usda.gov/food-details/170017/nutrients) Peas, green, frozen, cooked, boiled, drained, without salt |  |
| kukurydza konserwowa | 80 / 15 / 2.5 / 1.2 | 67 / 14.3 / 2.3 / 1.2 | **≠** | [169214](https://fdc.nal.usda.gov/food-details/169214/nutrients) Corn, sweet, yellow, canned, whole kernel, drained solids |  |
| fasola czerwona | 127 / 22.8 / 8.7 / 0.5 | 127 / 22.8 / 8.7 / 0.5 | ≈ | [175194](https://fdc.nal.usda.gov/food-details/175194/nutrients) Beans, kidney, red, mature seeds, cooked, boiled, without salt |  |
| awokado | 160 / 8.5 / 2 / 14.7 | 160 / 8.5 / 2 / 14.7 | ≈ | [171705](https://fdc.nal.usda.gov/food-details/171705/nutrients) Avocados, raw, all commercial varieties |  |
| pieczarki | 22 / 3.3 / 3.1 / 0.3 | 22 / 3.3 / 3.1 / 0.3 | ≈ | [169251](https://fdc.nal.usda.gov/food-details/169251/nutrients) Mushrooms, white, raw |  |
| szpinak | 23 / 3.6 / 2.9 / 0.4 | 23 / 3.6 / 2.9 / 0.4 | ≈ | [168462](https://fdc.nal.usda.gov/food-details/168462/nutrients) Spinach, raw |  |
| rzodkiewka | 16 / 3.4 / 0.7 / 0.1 | 16 / 3.4 / 0.7 / 0.1 | ≈ | [169276](https://fdc.nal.usda.gov/food-details/169276/nutrients) Radishes, raw |  |
| buraki | 44 / 10 / 1.7 / 0.2 | 44 / 10 / 1.7 / 0.2 | ≈ | [169146](https://fdc.nal.usda.gov/food-details/169146/nutrients) Beets, cooked, boiled, drained |  |
| cukinia | 17 / 3.1 / 1.2 / 0.3 | 17 / 3.1 / 1.2 / 0.3 | ≈ | [169291](https://fdc.nal.usda.gov/food-details/169291/nutrients) Squash, summer, zucchini, includes skin, raw |  |
| szczypiorek | 30 / 4 / 3 / 0.5 | 30 / 4.4 / 3.3 / 0.7 | ≈ | [169994](https://fdc.nal.usda.gov/food-details/169994/nutrients) Chives, raw |  |
| oliwki | 145 / 4 / 1 / 15 | 145 / 3.8 / 1 / 15.3 | ≈ | [169096](https://fdc.nal.usda.gov/food-details/169096/nutrients) Olives, pickled, canned or bottled, green | zielone |
| jabłko | 52 / 13.8 / 0.3 / 0.2 | 52 / 13.8 / 0.3 / 0.2 | ≈ | [171688](https://fdc.nal.usda.gov/food-details/171688/nutrients) Apples, raw, with skin (Includes foods for USDA's Food Distribution Program) |  |
| banan | 89 / 22.8 / 1.1 / 0.3 | 89 / 22.8 / 1.1 / 0.3 | ≈ | [173944](https://fdc.nal.usda.gov/food-details/173944/nutrients) Bananas, raw |  |
| gruszka | 57 / 15 / 0.4 / 0.1 | 57 / 15.2 / 0.4 / 0.1 | ≈ | [169118](https://fdc.nal.usda.gov/food-details/169118/nutrients) Pears, raw |  |
| pomarańcza | 47 / 11.8 / 0.9 / 0.1 | 47 / 11.8 / 0.9 / 0.1 | ≈ | [169097](https://fdc.nal.usda.gov/food-details/169097/nutrients) Oranges, raw, all commercial varieties |  |
| mandarynka | 53 / 13 / 0.8 / 0.3 | 53 / 13.3 / 0.8 / 0.3 | ≈ | [169105](https://fdc.nal.usda.gov/food-details/169105/nutrients) Tangerines, (mandarin oranges), raw |  |
| truskawki | 32 / 7.7 / 0.7 / 0.3 | 32 / 7.7 / 0.7 / 0.3 | ≈ | [167762](https://fdc.nal.usda.gov/food-details/167762/nutrients) Strawberries, raw |  |
| winogrona | 69 / 18 / 0.7 / 0.2 | 69 / 18.1 / 0.7 / 0.2 | ≈ | [174683](https://fdc.nal.usda.gov/food-details/174683/nutrients) Grapes, red or green (European type, such as Thompson seedless), raw |  |
| borówki | 57 / 14.5 / 0.7 / 0.3 | 57 / 14.5 / 0.7 / 0.3 | ≈ | [171711](https://fdc.nal.usda.gov/food-details/171711/nutrients) Blueberries, raw |  |
| maliny | 52 / 12 / 1.2 / 0.7 | 52 / 11.9 / 1.2 / 0.7 | ≈ | [167755](https://fdc.nal.usda.gov/food-details/167755/nutrients) Raspberries, raw |  |
| śliwki | 46 / 11.4 / 0.7 / 0.3 | 46 / 11.4 / 0.7 / 0.3 | ≈ | [169949](https://fdc.nal.usda.gov/food-details/169949/nutrients) Plums, raw |  |
| kiwi | 61 / 14.7 / 1.1 / 0.5 | 61 / 14.7 / 1.1 / 0.5 | ≈ | [168153](https://fdc.nal.usda.gov/food-details/168153/nutrients) Kiwifruit, green, raw |  |
| arbuz | 30 / 7.6 / 0.6 / 0.2 | 30 / 7.6 / 0.6 / 0.2 | ≈ | [167765](https://fdc.nal.usda.gov/food-details/167765/nutrients) Watermelon, raw |  |
| brzoskwinia | 39 / 9.5 / 0.9 / 0.3 | 39 / 9.5 / 0.9 / 0.3 | ≈ | [169928](https://fdc.nal.usda.gov/food-details/169928/nutrients) Peaches, yellow, raw |  |
| ananas | 50 / 13 / 0.5 / 0.1 | 50 / 13.1 / 0.5 / 0.1 | ≈ | [169124](https://fdc.nal.usda.gov/food-details/169124/nutrients) Pineapple, raw, all varieties |  |
| cytryna | 29 / 9 / 1.1 / 0.3 | 29 / 9.3 / 1.1 / 0.3 | ≈ | [167746](https://fdc.nal.usda.gov/food-details/167746/nutrients) Lemons, raw, without peel |  |
| rodzynki | 299 / 79 / 3 / 0.5 | 299 / 79.3 / 3.3 / 0.3 | ≈ | [168165](https://fdc.nal.usda.gov/food-details/168165/nutrients) Raisins, dark, seedless (Includes foods for USDA's Food Distribution Program) |  |
| daktyle | 282 / 75 / 2.5 / 0.4 | 282 / 75 / 2.5 / 0.4 | ≈ | [171726](https://fdc.nal.usda.gov/food-details/171726/nutrients) Dates, deglet noor |  |
| orzechy włoskie | 654 / 13.7 / 15 / 65 | 654 / 13.7 / 15.2 / 65.2 | ≈ | [170187](https://fdc.nal.usda.gov/food-details/170187/nutrients) Nuts, walnuts, english |  |
| migdały | 579 / 21.6 / 21 / 50 | 579 / 21.6 / 21.2 / 49.9 | ≈ | [170567](https://fdc.nal.usda.gov/food-details/170567/nutrients) Nuts, almonds |  |
| orzeszki ziemne | 585 / 16 / 26 / 49 | 587 / 21.3 / 24.4 / 49.7 | **≠** | [173806](https://fdc.nal.usda.gov/food-details/173806/nutrients) Peanuts, all types, dry-roasted, without salt |  |
| pestki dyni | 560 / 11 / 30 / 46 | 559 / 10.7 / 30.2 / 49.1 | **≠** | [170556](https://fdc.nal.usda.gov/food-details/170556/nutrients) Seeds, pumpkin and squash seed kernels, dried |  |
| olej rzepakowy | 884 / 0 / 0 / 100 | 884 / 0 / 0 / 100 | ≈ | [172336](https://fdc.nal.usda.gov/food-details/172336/nutrients) Oil, canola |  |
| oliwa z oliwek | 884 / 0 / 0 / 100 | 884 / 0 / 0 / 100 | ≈ | [171413](https://fdc.nal.usda.gov/food-details/171413/nutrients) Oil, olive, salad or cooking |  |
| majonez | 680 / 1 / 1 / 75 | 680 / 0.6 / 1 / 74.9 | ≈ | [171009](https://fdc.nal.usda.gov/food-details/171009/nutrients) Salad dressing, mayonnaise, regular |  |
| keczup | 100 / 24 / 1.5 / 0.2 | 101 / 27.4 / 1 / 0.1 | **≠** | [168556](https://fdc.nal.usda.gov/food-details/168556/nutrients) Catsup |  |
| miód | 304 / 82 / 0.3 / 0 | 304 / 82.4 / 0.3 / 0 | ≈ | [169640](https://fdc.nal.usda.gov/food-details/169640/nutrients) Honey |  |
| cukier | 400 / 100 / 0 / 0 | 387 / 100 / 0 / 0 | ≈ | [169655](https://fdc.nal.usda.gov/food-details/169655/nutrients) Sugars, granulated |  |
| krem czekoladowy | 540 / 58 / 6 / 31 | 539 / 62.4 / 5.4 / 29.7 | **≠** | [168000](https://fdc.nal.usda.gov/food-details/168000/nutrients) Chocolate-flavored hazelnut spread |  |
| masło orzechowe | 588 / 20 / 25 / 50 | 598 / 22.3 / 22.2 / 51.4 | ≈ | [172470](https://fdc.nal.usda.gov/food-details/172470/nutrients) Peanut butter, smooth style, without salt |  |
| hummus | 170 / 14 / 8 / 10 | 237 / 15 / 7.8 / 17.8 | **≠** | [174289](https://fdc.nal.usda.gov/food-details/174289/nutrients) Hummus, commercial |  |
| kawa czarna | 2 / 0 / 0.3 / 0 | 1 / 0 / 0.1 / 0 | ≈ | [171890](https://fdc.nal.usda.gov/food-details/171890/nutrients) Beverages, coffee, brewed, prepared with tap water |  |
| espresso | 2 / 0 / 0.1 / 0.2 | 9 / 1.7 / 0.1 / 0.2 | **≠** | [171891](https://fdc.nal.usda.gov/food-details/171891/nutrients) Beverages, coffee, brewed, espresso, restaurant-prepared |  |
| herbata | 1 / 0.2 / 0 / 0 | 1 / 0.3 / 0 / 0 | ≈ | [173227](https://fdc.nal.usda.gov/food-details/173227/nutrients) Beverages, tea, black, brewed, prepared with tap water |  |
| sok pomarańczowy | 45 / 10.4 / 0.7 / 0.2 | 45 / 10.4 / 0.7 / 0.2 | ≈ | [169098](https://fdc.nal.usda.gov/food-details/169098/nutrients) Orange juice, raw (Includes foods for USDA's Food Distribution Program) |  |
| sok jabłkowy | 46 / 11.3 / 0.1 / 0.1 | 46 / 11.3 / 0.1 / 0.1 | ≈ | [173933](https://fdc.nal.usda.gov/food-details/173933/nutrients) Apple juice, canned or bottled, unsweetened, without added ascorbic acid |  |
| cola | 42 / 10.6 / 0 / 0 | 41 / 10.6 / 0 / 0 | ≈ | [174851](https://fdc.nal.usda.gov/food-details/174851/nutrients) Beverages, carbonated, cola, without caffeine |  |
| napój energetyczny | 45 / 11 / 0 / 0 | 43 / 10.2 / 0.5 / 0 | ≈ | [173210](https://fdc.nal.usda.gov/food-details/173210/nutrients) Beverages, Energy drink, RED BULL |  |
| piwo | 43 / 3.6 / 0.5 / 0 | 43 / 3.6 / 0.5 / 0 | ≈ | [168746](https://fdc.nal.usda.gov/food-details/168746/nutrients) Alcoholic beverage, beer, regular, all |  |
| wino czerwone | 85 / 2.6 / 0.1 / 0 | 85 / 2.6 / 0.1 / 0 | ≈ | [173190](https://fdc.nal.usda.gov/food-details/173190/nutrients) Alcoholic beverage, wine, table, red |  |
| wódka | 230 / 0 / 0 / 0 | 231 / 0 / 0 / 0 | ≈ | [174815](https://fdc.nal.usda.gov/food-details/174815/nutrients) Alcoholic beverage, distilled, all (gin, rum, vodka, whiskey) 80 proof |  |
| kakao | 80 / 11 / 3.5 / 2.5 | 77 / 10.7 / 3.5 / 2.3 | ≈ | [171277](https://fdc.nal.usda.gov/food-details/171277/nutrients) Milk, chocolate beverage, hot cocoa, homemade | na mleku |
| czekolada mleczna | 535 / 59 / 7.6 / 30 | 535 / 59.4 / 7.7 / 29.7 | ≈ | [167587](https://fdc.nal.usda.gov/food-details/167587/nutrients) Candies, milk chocolate |  |
| czekolada gorzka | 598 / 46 / 7.8 / 43 | 598 / 45.9 / 7.8 / 42.6 | ≈ | [170273](https://fdc.nal.usda.gov/food-details/170273/nutrients) Chocolate, dark, 70-85% cacao solids | 70–85% kakao |
| lody | 210 / 24 / 3.5 / 11 | 207 / 23.6 / 3.5 / 11 | ≈ | [167575](https://fdc.nal.usda.gov/food-details/167575/nutrients) Ice creams, vanilla | waniliowe |
| chipsy | 540 / 53 / 6.5 / 34 | 532 / 53.8 / 6.4 / 34 | ≈ | [169677](https://fdc.nal.usda.gov/food-details/169677/nutrients) Snacks, potato chips, plain, salted |  |
| paluszki słone | 380 / 75 / 10 / 4 | 384 / 80.4 / 10 / 2.9 | **≠** | [167555](https://fdc.nal.usda.gov/food-details/167555/nutrients) Snacks, pretzels, hard, plain, salted | precle |
| gofr | 290 / 35 / 7 / 14 | 291 / 32.9 / 7.9 / 14.1 | ≈ | [175039](https://fdc.nal.usda.gov/food-details/175039/nutrients) Waffles, plain, prepared from recipe |  |
| pizza | 250 / 32 / 11 / 9 | 268 / 29 / 10.4 / 12.3 | **≠** | [170317](https://fdc.nal.usda.gov/food-details/170317/nutrients) Pizza, cheese topping, regular crust, frozen, cooked | z serem, mrożona, upieczona |

## Polski produkt różni się od amerykańskiego — zostają nasze wartości (46)

USDA tylko dla porównania; te produkty zostają `verified: false`.

| Produkt | Przed (kcal / W / B / T) | USDA | | Pozycja USDA | Uwagi |
|---|---|---|---|---|---|
| bułka pełnoziarnista | 255 / 46 / 10 / 3.5 | 252 / 42.7 / 12.5 / 3.5 | **≠** | [172688](https://fdc.nal.usda.gov/food-details/172688/nutrients) Bread, whole-wheat, commercially prepared | chleb pełnoziarnisty USA |
| bułka maślana | 330 / 55 / 8.5 / 8 | 321 / 53.6 / 10 / 7.4 | ≈ | [174107](https://fdc.nal.usda.gov/food-details/174107/nutrients) Rolls, dinner, sweet | amerykańska słodka bułka obiadowa |
| chleb pszenny | 245 / 50 / 7.5 / 1.5 | 266 / 49.4 / 8.9 / 3.3 | ≈ | [174924](https://fdc.nal.usda.gov/food-details/174924/nutrients) Bread, white, commercially prepared (includes soft bread crumbs) | amerykański chleb biały ma dodatek cukru i tłuszczu |
| chleb żytni | 230 / 48 / 6 / 1.5 | 259 / 48.3 / 8.5 / 3.3 | ≈ | [172684](https://fdc.nal.usda.gov/food-details/172684/nutrients) Bread, rye | amerykański chleb żytni jest mieszany z pszenicą |
| chleb razowy | 220 / 45 / 6 / 1.6 | 250 / 47.5 / 8.7 / 3.1 | ≈ | [174918](https://fdc.nal.usda.gov/food-details/174918/nutrients) Bread, pumpernickel | pumpernikiel |
| pączek | 400 / 48 / 6 / 20 | 421 / 47.9 / 6.1 / 22.7 | ≈ | [172758](https://fdc.nal.usda.gov/food-details/172758/nutrients) Doughnuts, yeast-leavened, glazed, enriched (includes honey buns) | amerykański donut glazurowany, bez nadzienia |
| drożdżówka | 330 / 52 / 7 / 10 | 372 / 50.9 / 6.2 / 16.4 | **≠** | [175034](https://fdc.nal.usda.gov/food-details/175034/nutrients) Sweet rolls, cinnamon, commercially prepared with raisins | cynamonka z rodzynkami |
| naleśnik | 210 / 28 / 7 / 8 | 227 / 28.3 / 6.4 / 9.7 | ≈ | [175009](https://fdc.nal.usda.gov/food-details/175009/nutrients) Pancakes, plain, prepared from recipe | amerykański pancake jest grubszy, z proszkiem do pieczenia |
| margaryna | 535 / 0.5 / 0.2 / 60 | 713 / 0.8 / 0.2 / 80.2 | **≠** | [172347](https://fdc.nal.usda.gov/food-details/172347/nutrients) Margarine, regular, 80% fat, composite, tub, with salt | USDA 80% tłuszczu; polskie margaryny kubkowe zwykle 60% |
| jogurt naturalny | 60 / 6 / 4.3 / 2 | 61 / 4.7 / 3.5 / 3.3 | ≈ | [171284](https://fdc.nal.usda.gov/food-details/171284/nutrients) Yogurt, plain, whole milk | USDA z mleka pełnego 3,25%; polski zwykle 2–3% |
| jogurt grecki | 130 / 4 / 3.5 / 10 | 97 / 4 / 9 / 5 | **≠** | [171304](https://fdc.nal.usda.gov/food-details/171304/nutrients) Yogurt, Greek, plain, whole milk | polski „typu greckiego” to 10% tłuszczu i ~3,5% białka, amerykański greek to odcedzony |
| jogurt owocowy | 95 / 14 / 3.5 / 2.5 | 105 / 18.6 / 4.9 / 1.4 | **≠** | [171286](https://fdc.nal.usda.gov/food-details/171286/nutrients) Yogurt, fruit, low fat, 11g protein/8 oz |  |
| kefir | 50 / 4.5 / 3.4 / 2 | 43 / 4.8 / 3.8 / 1 | **≠** | [170904](https://fdc.nal.usda.gov/food-details/170904/nutrients) Kefir, lowfat, plain, LIFEWAY | USDA 1%; polski zwykle 2% |
| maślanka | 38 / 4.7 / 3.4 / 0.6 | 40 / 4.8 / 3.3 / 1.1 | ≈ | [170874](https://fdc.nal.usda.gov/food-details/170874/nutrients) Milk, buttermilk, fluid, cultured, lowfat | USDA 1%; polska 0,5% |
| śmietana 18% | 185 / 3.6 / 2.5 / 18 | 198 / 4.6 / 2.4 / 19.4 | ≈ | [171257](https://fdc.nal.usda.gov/food-details/171257/nutrients) Cream, sour, cultured | USDA 19,4% tłuszczu; nasza 18% |
| mozzarella | 250 / 2 / 18 / 19 | 299 / 2.4 / 22.2 / 22.1 | **≠** | [170845](https://fdc.nal.usda.gov/food-details/170845/nutrients) Cheese, mozzarella, whole milk | USDA to mozzarella amerykańska; polska w zalewie ma więcej wody |
| serek wiejski | 97 / 2 / 11 / 5 | 98 / 3.4 / 11.1 / 4.3 | ≈ | [172179](https://fdc.nal.usda.gov/food-details/172179/nutrients) Cheese, cottage, creamed, large or small curd | cottage cheese |
| serek topiony | 250 / 6 / 10 / 21 | 371 / 3.7 / 18.1 / 31.8 | **≠** | [171290](https://fdc.nal.usda.gov/food-details/171290/nutrients) Cheese, pasteurized process, American, without added vitamin D | amerykański ser topiony w plastrach |
| serek kanapkowy | 250 / 4 / 6 / 23 | 350 / 5.5 / 6.2 / 34.4 | **≠** | [173418](https://fdc.nal.usda.gov/food-details/173418/nutrients) Cheese, cream | cream cheese; polskie serki kanapkowe są lżejsze |
| szynka | 115 / 1.5 / 19 / 4 | 122 / 0 / 19.6 / 4.3 | ≈ | [167874](https://fdc.nal.usda.gov/food-details/167874/nutrients) Pork, cured, ham, steak, boneless, extra lean, unheated | amerykańska szynka extra lean |
| szynka drobiowa | 100 / 2 / 19 / 2 | 79 / 2.2 / 16.8 / 0.4 | **≠** | [172963](https://fdc.nal.usda.gov/food-details/172963/nutrients) Chicken breast, oven-roasted, fat-free, sliced | amerykańska pierś pieczona w plastrach, bez tłuszczu |
| polędwica | 105 / 1 / 20 / 2.5 | 122 / 0 / 19.6 / 4.3 | ≈ | [167874](https://fdc.nal.usda.gov/food-details/167874/nutrients) Pork, cured, ham, steak, boneless, extra lean, unheated |  |
| kiełbasa | 270 / 1.5 / 15 / 23 | 301 / 2 / 12.1 / 26.6 | **≠** | [172954](https://fdc.nal.usda.gov/food-details/172954/nutrients) Sausage, Polish, pork and beef, smoked | amerykańska kiełbasa polska wieprzowo-wołowa |
| pasztet | 280 / 5 / 12 / 24 | 319 / 1.5 / 14.2 / 28 | **≠** | [172930](https://fdc.nal.usda.gov/food-details/172930/nutrients) Pate, liver, not specified, canned |  |
| kotlet drobiowy panierowany | 230 / 10 / 20 / 12 | 260 / 9 / 24.8 / 13.2 | **≠** | [171475](https://fdc.nal.usda.gov/food-details/171475/nutrients) Chicken, broilers or fryers, breast, meat and skin, cooked, fried, batter | pierś w cieście ze skórą |
| mięso mielone | 250 / 0 / 17 / 20 | 263 / 0 / 16.9 / 21.2 | ≈ | [167902](https://fdc.nal.usda.gov/food-details/167902/nutrients) Pork, fresh, ground, raw | surowe wieprzowe |
| ryba panierowana | 220 / 14 / 15 / 12 | 277 / 21.7 / 11 / 16.2 | **≠** | [174195](https://fdc.nal.usda.gov/food-details/174195/nutrients) Fish, fish sticks, frozen, prepared | paluszki rybne |
| śledź w oleju | 250 / 1 / 15 / 21 | 262 / 9.6 / 14.2 / 18 | **≠** | [175118](https://fdc.nal.usda.gov/food-details/175118/nutrients) Fish, herring, Atlantic, pickled | marynowany, nie w oleju |
| makrela wędzona | 225 / 0 / 21 / 15 | 262 / 0 / 23.9 / 17.8 | ≈ | [175120](https://fdc.nal.usda.gov/food-details/175120/nutrients) Fish, mackerel, Atlantic, cooked, dry heat | pieczona, nie wędzona |
| ziemniaki pieczone | 140 / 22 / 2.5 / 4.5 | 93 / 21.2 / 2.5 / 0.1 | **≠** | [170093](https://fdc.nal.usda.gov/food-details/170093/nutrients) Potatoes, baked, flesh and skin, without salt | USDA bez tłuszczu; nasze z olejem |
| ogórek konserwowy | 25 / 5 / 0.6 / 0.2 | 91 / 21.2 / 0.6 / 0.4 | **≠** | [169378](https://fdc.nal.usda.gov/food-details/169378/nutrients) Pickles, cucumber, sweet (includes bread and butter pickles) | amerykańskie słodkie pikle; polskie konserwowe mniej słodkie |
| musztarda | 120 / 10 / 5.5 / 6 | 60 / 5.8 / 3.7 / 3.3 | **≠** | [172234](https://fdc.nal.usda.gov/food-details/172234/nutrients) Mustard, prepared, yellow | amerykańska żółta; polskie (sarepska, kremska) słodsze |
| dżem | 250 / 62 / 0.4 / 0.1 | 278 / 68.9 / 0.4 / 0.1 | **≠** | [169641](https://fdc.nal.usda.gov/food-details/169641/nutrients) Jams and preserves | polskie dżemy często niskosłodzone |
| kakao w proszku | 290 / 22 / 20 / 13 | 228 / 57.9 / 19.6 / 13.7 | **≠** | [169593](https://fdc.nal.usda.gov/food-details/169593/nutrients) Cocoa, dry powder, unsweetened | u nas węglowodany bez błonnika (37 g) |
| baton czekoladowy | 490 / 60 / 8 / 24 | 491 / 61.5 / 7.5 / 23.9 | ≈ | [169589](https://fdc.nal.usda.gov/food-details/169589/nutrients) Candies, MARS SNACKFOOD US, SNICKERS Bar | snickers |
| baton musli | 400 / 65 / 6 / 13 | 471 / 64.4 / 10.1 / 19.8 | **≠** | [167542](https://fdc.nal.usda.gov/food-details/167542/nutrients) Snacks, granola bars, hard, plain |  |
| ciastko | 480 / 70 / 6 / 20 | 467 / 68.9 / 6.1 / 18.8 | ≈ | [174950](https://fdc.nal.usda.gov/food-details/174950/nutrients) Cookies, butter, commercially prepared, enriched | kruche maślane |
| ciasto | 350 / 45 / 6 / 16 | 379 / 55.4 / 3.2 / 17.8 | **≠** | [174944](https://fdc.nal.usda.gov/food-details/174944/nutrients) Cake, yellow, commercially prepared, with chocolate frosting, in-store bakery | biszkopt z polewą |
| sernik | 290 / 25 / 8 / 18 | 321 / 25.5 / 5.5 / 22.5 | **≠** | [172711](https://fdc.nal.usda.gov/food-details/172711/nutrients) Cake, cheesecake, commercially prepared | amerykański cheesecake z serka śmietankowego |
| szarlotka | 260 / 38 / 3 / 11 | 237 / 34 / 1.9 / 11 | **≠** | [175011](https://fdc.nal.usda.gov/food-details/175011/nutrients) Pie, apple, commercially prepared, enriched flour | amerykański apple pie |
| żelki | 340 / 77 / 6 / 0.2 | 396 / 98.9 / 0 / 0 | **≠** | [167989](https://fdc.nal.usda.gov/food-details/167989/nutrients) Candies, gumdrops, starch jelly pieces | żelki skrobiowe, bez żelatyny |
| budyń | 105 / 18 / 3 / 2.5 | 130 / 22.6 / 1.5 / 3.8 | **≠** | [169608](https://fdc.nal.usda.gov/food-details/169608/nutrients) Puddings, vanilla, ready-to-eat | gotowy deser USA |
| zupa pomidorowa | 45 / 6 / 1 / 2 | 32 / 7.5 / 0.7 / 0.2 | **≠** | [171176](https://fdc.nal.usda.gov/food-details/171176/nutrients) Soup, tomato, canned, prepared with equal volume water, commercial | zupa z puszki rozcieńczona wodą, bez śmietany |
| rosół | 25 / 1.5 / 2 / 1.2 | 6 / 0.4 / 0.6 / 0.2 | **≠** | [174536](https://fdc.nal.usda.gov/food-details/174536/nutrients) Soup, chicken broth, ready-to-serve | bulion bez makaronu |
| grochówka | 95 / 11 / 5.5 / 3.5 | 61 / 9.9 / 3.2 / 1.1 | **≠** | [174561](https://fdc.nal.usda.gov/food-details/174561/nutrients) Soup, pea, green, canned, prepared with equal volume water | z puszki, bez kiełbasy |
| hamburger | 250 / 25 / 13 / 11 | 263 / 29.6 / 13.3 / 10.2 | **≠** | [170694](https://fdc.nal.usda.gov/food-details/170694/nutrients) Fast foods, hamburger; single, regular patty; with condiments | fast food z dodatkami |

## Bez odpowiednika w USDA (48)

bułka żytnia, bułka grahamka, mleko owsiane, skyr, twaróg półtłusty, twaróg chudy, twaróg tłusty, serek homogenizowany, szynka parmeńska, kiełbasa krakowska, kabanos, kotlet schabowy, kotlet mielony, musli, kopytka, surówka, warzywa gotowane, sos czosnkowy, sos bolognese, woda, cola zero, piwo bezalkoholowe, smoothie, latte, wafelek, żurek, barszcz czerwony, zupa ogórkowa, krupnik, kapuśniak, zupa jarzynowa, flaki, pierogi, pierogi z mięsem, pierogi z kapustą i grzybami, pierogi z serem, uszka, bigos, gołąbki, gulasz, leczo, kebab, zapiekanka, sałatka grecka, sałatka jarzynowa, sushi, pasta jajeczna, kanapka gotowa.

Do sprawdzenia z etykietami lub tabelami NIZP-PZH (Kunachowicz i in., „Tabele składu i wartości odżywczej żywności”).
