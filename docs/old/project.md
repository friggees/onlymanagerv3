**Summary**
we are gonna build a few sections of the backend of my manager platform for onlyfans models that will be connected to eachother, this specific part that binds our sections together is the economy part, so everything regarding it.


**To properly build it we need to take a few things into account, lets start with all the ways income can be added to the platform**
One page of the platform is **Register Income** its mainly for Chatters, Managers and Owner users and the inputs should be:
    * First option will be choosing if its a message or tip sale and 
    * Gross Sale Amount 
    * Date of sale 
    * Customer username from OnlyFans
    * Detect which user that 
    registers the sale automatically and link it to that person
    * Choosing which model the sale was on
    (dropdown of model list will eventually be connected, so we need to make sure its easy to connect it to the models later on, and the user that uses the platform should only see the models they have been assigned to, but assigning models will be in a completely different part of the platform so we need to leave it open for developing there later on)


Chatters registering their sales will for most buyers of the platform be the main source of income, but a lot of agency owners also sell side-products so thats why we also will give owners possibility to add other income on the same page, but it should not be shown to normal users as Chatter or Managers by default.

So in the register income page for owners this should fall into effect:
* if a owner is on the register sales page a third option should be visible where that user can choose if its "other" instead of messages or tips
* When choosing "other" most input fields will change;
* source of income
* date of income
* option to choose if it should repeat, and with a mini calendar choose which date of the month with possibility to choose several dates, maybe its weekly etc.
* option to add a percentage or fixed amount to another user of that sale 

**Now I will align the details regarding how the money is split up between users automatically, and what should be deducted because of fee's and what not**

*  The Onlyfans fee should be removed from the gross amount, which in most cases are 20% and it needs to be adjustable BY OWNERS from etc settings page, but we are not gonna build settings page now so we need to make sure we can easily implement adjustable fee removal later on in the project, so the employees salary is based on their NET sale amount, not gross, but they will add gross.

* Commission to the employee (model, chatter, manager) needs to be accounted for which is set by the owner on the employee page or when adding new employees (which also is another page of the platform we wont directly be working on now, so we need to make sure we can asily implement adjustable commission percentages later on in the project)

* Fixed salary amount to the employee (model, chatter, manager) needs to be accounted for which is set by the owner on the employee page or when adding new employees (which also is another page of the platform we wont directly be working on now, so we need to make sure we can asily implement adjustable fixed salaries later on in the project)

* Combined salary amount and commissions to the employee (model, chatter, manager) needs to be accounted for which is set by the owner on the employee page or when adding new employees (which also is another page of the platform we wont directly be working on now, so we need to make sure we can asily implement adjustable fixed salaries later on in the project)

* Passive Manager Tick from his assigned chatters needs to be accounted for which is set by the owner on the employee page or when adding new employees (which also is another page of the platform we wont directly be working on now, so we need to make sure we can asily implement adjustable fixed salaries later on in the project)

* And the remaining money is the profit to the agency

*So any percentage commissions should be based on the NET amount sales, not gross*

Another important part to know is that Owners will have the possibility to choose 'split chatting costs' when adding a model in the employee page or viewing that specific employee, (which also is another page of the platform we wont directly be working on now, so we need to make sure we can easily implement that later on in the project, because when chatting costs are split agency would earn 50% of the chatters commission more as profit and models would lose 50% of the chatters commissions as profit.)

Here are examples of some different calculations on how the salary is divided:

# 📊 CHATTARE FAST + PROVISION, MODELL FAST

## 📦 FÖRUTSÄTTNINGAR
- **Total försäljning (GROSS):** 10 000 $
- **OF tar 20 % avgift:** 2 000 $
- **NET (GROSS – 20 %):** 8 000 $

---

## 👥 ROLLSPECIFIKA INSTÄLLNINGAR

### 🧑‍💻 Chattare
- Fast lön: **200 $ / månad**
- Provision: **5 % av NET**
  - 5 % av 8 000 $ = **400 $**

### 👩‍🎤 Modell
- Fast lön: **800 $ / månad**
- Ingen provision

### 🏢 Agency
- Får det som blir kvar efter löner och utgifter

---

## 💵 LÖNEKOSTNADER

| Roll        | Typ            | Belopp     |
|-------------|----------------|------------|
| Chattare    | Fast lön       | 200 $      |
| Chattare    | Provision (5%) | 400 $      |
| Modell      | Fast lön       | 800 $      |
| **Totalt**  |                | **1 400 $** |


---

## 💰 VALFRIA INTÄKTER

| Namn                        | Belopp |
|-----------------------------|--------|
| Försäljning av Twitter-bot | +250 $ |

---

## 📊 SAMMANSTÄLLNING

1. **NET efter OF avgift:**  
   10 000 $ – 2 000 $ = **8 000 $**

2. **Minus löner & provisioner:**  
   –1 400 $

3. **Minus utgifter:**  
   –449 $

4. **Plus extra intäkt:**  
   +250 $

---

## ✅ SLUTGILTIG AGENCYVINST

**8 000 – 1 400 – 449 + 250 = 6 401 $**

---

## 📌 SLUTSAMMANSTÄLLNING

| Post        | Belopp               |
|-------------|----------------------|
| Modell      | 800 $ (fast lön)     |
| Chattare    | 200 $ + 400 $ = 600 $ |
| Utgifter    | 449 $                |
| **Agency**  | **6 401 $ vinst** ✅ |

Sen om det finns flera modeller under samma agency så tas alla beräkningar i akt


# 📊 MÅNADSBERÄKNING – PROVISIONSMODELL FÖR MODELL + CHATTARE

## 📦 FÖRUTSÄTTNINGAR
- **Total försäljning (GROSS):** 10 000 $
- **OF tar 20 % avgift:** 2 000 $
- **NET (GROSS – 20 %):** 8 000 $

---

## 👥 ROLLSPECIFIKA INSTÄLLNINGAR

### 🧑‍💻 Chattare
- Fast lön: **200 $ / månad**
- Provision: **5 % av NET**
  - 5 % av 8 000 = **400 $**

### 👩‍🎤 Modell
- Provision: **35 % av NET**
  - 35 % av 8 000 = **2 800 $**

### 🏢 Agency
- Får det som blir kvar efter:
  - Chattarlön + provision
  - Modellens provision
  - Eventuella utgifter
  - Justeras med valfria intäkter

---

## 💵 LÖNEKOSTNADER

| Roll        | Typ            | Belopp     |
|-------------|----------------|------------|
| Chattare    | Fast lön       | 200 $      |
| Chattare    | Provision (5%) | 400 $      |
| Modell      | Provision (35%)| 2 800 $    |
| **Totalt**  |                | **3 400 $** |

---

## 💸 UTGIFTER

| Namn                        | Typ            | Belopp |
|-----------------------------|----------------|--------|
| OnlyManager Subscription    | Återkommande   | 299 $  |
| Instagram Ads               | Engångskostnad | 150 $  |
| **Totalt**                  |                | **449 $** |

---

## 💰 VALFRIA INTÄKTER

| Namn                        | Belopp |
|-----------------------------|--------|
| Försäljning av Twitter-bot | +250 $ |

---

## 📊 SAMMANSTÄLLNING

1. **NET efter OF avgift:**  
   10 000 $ – 2 000 $ = **8 000 $**

2. **Minus löner & provisioner:**  
   –3 400 $

3. **Minus utgifter:**  
   –449 $

4. **Plus extra intäkt:**  
   +250 $

---

## ✅ SLUTGILTIG AGENCYVINST

**8 000 – 3 400 – 449 + 250 = 4 401 $**

---

## 📌 SLUTSAMMANSTÄLLNING

| Post        | Belopp               |
|-------------|----------------------|
| Modell      | 2 800 $ (35 % provision) |
| Chattare    | 200 $ + 400 $ = 600 $ |
| Utgifter    | 449 $                |
| **Agency**  | **4 401 $ vinst** ✅ |

**Now we know what every person should earn and how the money is divided**

**Next page that is important that we have backend for is 'expenses' which will be a tab in the statistics page, its necessary to be able to deduct expenses from agency/owner profits**
* Choose expenses amount 
* Choose if its repetitive, daily, weekly or monthly and which date
* Choose source of expense



**Now for the statistics page and specifically everything regarding money the owners or assigned users should be able to see:**
* Free period range, or daily, weekly and monthly.
* Total income
* Total Expense
* Total amount of sales
* Top 5 earners (employees)
* AFV (Average Fan Value)
*For the AFV we will have a seperate scraper that checks the current total subscriber count on the models pages to be able to count AFV, Average Fan Value of each chatter and total per model, the scraper is seperate and my friend is building it so the system needs to take this into account when calculating the AFV (total net earnings divided by total subscriber amount shows the AFV)*
* AFV Percentual trend based on the period range showing both seperate chatters AFV and AFV for the model

**Period range trend AFV calculations examples:**
If a chatter sold for total of 1000$ and the model has a subscriber count of 200, the AFV is: 5$

So if the next day its 10$ AFV his trend AFV is 100%, it needs to remember his past AFV to be able to calculate the trend.
**Period range trend calculations examples:**
Daily: If the chatter sold 100$ yesterday and today for 100$ its a 0% trend, if he sold 100$ yesterday and 200$ today its 100% trend and if he sold for 100$ yesterday and 50$ today its a -50% trend

Same goes with weekly but it would base it on last week results

Same goes with monthly but it would base it on last monthly results

Same goes if a model has 1000$ in daily income splitted on all chatters, etc 

Chatter 1: 100$
Chatter 2: 100$

And next day they both do 200$ instead, here its also 100% increase, same goes with weekly, but based on last week result, and same with monthly, but last month results.

**Another part of the statistics page is being able to see the timetracking of employees:**
* If a chatter checks in 2 minutes late it would add those 2 minutes as late arrival on that employee, if he misses a shift completely it would also mark that, if he doesnt check out at all it would also mark that, if he checks out late it would also mark how long

This way we can calculate trends for employees in how responsible they are, see total minutes late etc

Its also important because in settings page that we wont work on now the purchaser of the platform in the future will be able to choose XX$ amount to deduct if X minutes late, or XX$ amount to deduct if missing check-in completely 

