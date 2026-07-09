const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());

app.use(express.json());

app.get('/api/message', (req, res) => {
    res.json({ message: 'car parking system backend is running and connect to react' });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {

    console.log('Server is running on port ${PORT}');
});

app.get("/", (req, res) => {
    res.send("Welcome to backend of car parking system");
});