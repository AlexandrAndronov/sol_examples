Отлично — сделаю пошаговую «реальную» инструкцию от нуля до деплоя в сеть (я покажу на примере **Sepolia — тестовой сети**; в неё безопасно деплоить сначала, а потом те же шаги можно использовать для Mainnet, только с реальным RPC и настоящими ключами). Буду давать команды, файлы и объяснения — копируй и выполняй прямо в терминале.

> Коротко: для деплоя Hardhat должен знать RPC-URL сети (Infura/Alchemy/другой провайдер) и приватный ключ аккаунта (в `.env`). Hardhat умеет деплоить и в тестсети, и в Mainnet. ([hardhat.org][1])

---

# 0) Требования (что установить)

* Node.js (рекомендую 18+).
* npm или yarn.
* Метамаск (для просмотра/взаимодействия) — добавьте сеть Sepolia и получите тест-ETH через faucet (если нужно). ([ChainList][2])

---

# 1) Создаем папку проекта и инициализируем npm

```bash
mkdir my-hardhat-project
cd my-hardhat-project
npm init -y
```

---

# 2) Устанавливаем Hardhat и зависимости

(установим сам Hardhat, ethers и плагины для верификации; использую npm)

```bash
npm install --save-dev hardhat
npm install --save-dev @nomicfoundation/hardhat-toolbox
# toolbox включает ethers, waffle, и плагины для тестирования и верификации
```

(если хотите использовать `hardhat-deploy` — можно добавить, но в этом примере обойдёмся Ignite/скриптами из официального набора). ([hardhat.org][3])

---

# 3) Инициализация Hardhat проекта (шаблон)

```bash
npx hardhat init
# или
npx hardhat
# и выбрать "Create a basic sample project" → следовать подсказкам
```

После этого у вас появится структура вроде `contracts/`, `scripts/`, `test/`, `hardhat.config.*`. ([hardhat.org][4])

---

# 4) Пишем простой контракт (пример)

Создайте файл `contracts/Hello.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Hello {
    string public greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function setGreeting(string memory _g) public {
        greeting = _g;
    }
}
```

---

# 5) Настройка переменных окружения (RPC + приватный ключ)

Создайте `.env` в корне проекта (ни в коем случае не коммитить в git):

```
SEPOLIA_RPC=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
PRIVATE_KEY=0xYOUR_PRIVATE_KEY_WITHOUT_0x_PREFIX? NO — с 0x лучше оставить
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY   # для верификации (опционально)
```

* `SEPOLIA_RPC` можно получить в Alchemy / Infura. ([Alchemy][5])
* Получить тестовые ETH — через faucet (Alchemy/другие) после добавления сети в MetaMask. ([web3.university][6])

Установим dotenv:

```bash
npm install --save-dev dotenv
```

---

# 6) Конфигурация Hardhat (`hardhat.config.js`)

Простой конфиг, использующий toolbox:

```js
require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.19",
  networks: {
    hardhat: {},
    sepolia: {
      url: process.env.SEPOLIA_RPC || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    // mainnet: { url: process.env.MAINNET_RPC, accounts: [process.env.PRIVATE_KEY] } // когда понадобится
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || ""
  }
};
```

> `hardhat-toolbox` включает плагины для проверки (verify), тестирования и т.д. ([hardhat.org][1])

---

# 7) Скрипт деплоя

Создайте `scripts/deploy.js`:

```js
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const Hello = await ethers.getContractFactory("Hello");
  const hello = await Hello.deploy("Привет, Sepolia!");
  await hello.waitForDeployment();

  console.log("Hello deployed to:", hello.target); // в hardhat vX могут быть методы .target или .address
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

(если у вас старые версии, вместо `waitForDeployment()` может использоваться `await hello.deployed()` и `hello.address` — конфиг зависит от версии Hardhat/ethers; официальная документация показывает текущие варианты). ([hardhat.org][7])

---

# 8) Компиляция и локальный запуск (проверка)

Компилируем:

```bash
npx hardhat compile
```

Запустим локальную сеть для тестов:

```bash
npx hardhat node
# в другом терминале можно запускать скрипты с --network localhost
```

---

# 9) Деплой в Sepolia (тестовая сеть)

Убедитесь, что в `.env` установлен `SEPOLIA_RPC` и `PRIVATE_KEY` (средства на аккаунте не обязательны для тестнета, но нужны для Mainnet).

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

Вывод покажет адрес деплоенного контракта. Если ошибка — проверьте RPC, ключ, и что у аккаунта есть тест-ETH. ([hardhat.org][8])

---

# 10) Верификация контракта на Etherscan (опционально, но рекомендуем)

1. Получите `ETHERSCAN_API_KEY` (Etherscan.io → API Keys).
2. В `hardhat.config.js` уже указан `etherscan`.
3. Выполните:

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> "Привет, Sepolia!"
```

Hardhat попытается автоматически отправить исходники и параметры компиляции в Etherscan. Подробно — в официальном гайде по верификации. ([hardhat.org][9])

---

# 11) Взаимодействие с контрактом (пример короткого скрипта)

Создайте `scripts/interact.js`:

```js
async function main() {
  const contractAddress = "0x..."; // адрес от деплоя
  const Hello = await ethers.getContractFactory("Hello");
  const hello = Hello.attach(contractAddress);

  console.log("Current greeting:", await hello.greeting());
  const tx = await hello.setGreeting("Новое приветствие");
  await tx.wait();
  console.log("Updated:", await hello.greeting());
}

main().catch(console.error);
```

Запуск:

```bash
npx hardhat run scripts/interact.js --network sepolia
```

---

# Полезные советы и замечания

* Всегда сначала деплойте в тестнет (Sepolia) — так можно проверить логику и газ-потребление без рисков и затрат. ([hardhat.org][8])
* Не храните приватные ключи в репозитории! Используйте `.env` и `.gitignore`.
* Для Mainnet используйте провайдеры (Alchemy/Infura) с тарифами и убедитесь, что на кошельке достаточно ETH. ([Infura][10])
* Если Hardhat по умолчанию деплоит в локальную сеть — это ожидаемо; для реального деплоя указывайте `--network <name>` или настройте конфиг. ([hardhat.org][1])

---

# Если хочешь — дам:

* Готовый `package.json` с командами (`compile`, `deploy:sepolia`, `verify:sepolia`),
* Скрипт для проверки баланса и получения тест ETH (faucet),
* Пример `.gitignore` и безопасный workflow для CI/CD (deploy с GitHub Actions).

Скажи что из этого хочешь — и я сразу сгенерирую файлы/команды под твой проект.

[1]: https://hardhat.org/docs/getting-started?utm_source=chatgpt.com "Getting started with Hardhat 3"
[2]: https://chainlist.org/chain/11155111?utm_source=chatgpt.com "Ethereum Sepolia RPC and Chain settings"
[3]: https://hardhat.org/hardhat-runner/docs/getting-started?utm_source=chatgpt.com "Getting started with Hardhat | Ethereum development ..."
[4]: https://hardhat.org/tutorial/creating-a-new-hardhat-project?utm_source=chatgpt.com "3. Creating a new Hardhat project | Ethereum development ..."
[5]: https://www.alchemy.com/chain-connect/chain/sepolia?utm_source=chatgpt.com "Ethereum Sepolia RPC URL & devtools"
[6]: https://www.web3.university/article/how-to-add-sepolia-to-metamask?utm_source=chatgpt.com "How to Add Sepolia to MetaMask"
[7]: https://hardhat.org/docs/guides/deployment/using-scripts?utm_source=chatgpt.com "Deploying smart contracts using scripts"
[8]: https://hardhat.org/docs/guides/deployment?utm_source=chatgpt.com "Deployment overview"
[9]: https://hardhat.org/docs/guides/smart-contract-verification?utm_source=chatgpt.com "Verifying smart contracts"
[10]: https://www.infura.io/?utm_source=chatgpt.com "Infura - Home | Web3 Development Platform | IPFS API ..."
