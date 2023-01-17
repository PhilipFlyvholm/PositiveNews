let current = 0;
let options = {
    root: null,
    rootMargin: "0px",
    threshold: buildThresholdList()
};
function buildThresholdList() {
    let thresholds = [];
    let numSteps = 20;

    for (let i=1.0; i<=numSteps; i++) {
        let ratio = i/numSteps;
        thresholds.push(ratio);
    }

    thresholds.push(0);
    return thresholds;
}
const observer = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
        if (entry.intersectionRatio > 0.5) {
            current = entry.target.dataset.articleNr;
            entry.target.classList.add("current")
        }else{
            entry.target.classList.remove("current")
        }
    });
}, options);

window.addEventListener('load', () => {
    const articles = document.querySelectorAll('.article');
    articles.forEach(article => {
        observer.observe(article);
    });

    const sourceInputs = document.querySelectorAll('input.source-input');
    const articleList = document.getElementById("article-list");
    sourceInputs.forEach((el) => {
        el.addEventListener('click', (_) =>{
            if(el.checked) articleList.classList.remove('hide-' + el.id);
            else articleList.classList.add('hide-' + el.id);

        })
    })
})

window.addEventListener('keydown', (e) => {

    switch (e.key) {
        case 'ArrowUp':{
            if(current <= 0){
                current = 0;
                break
            }
            e.preventDefault()
            current--
            const article = document.querySelector(`.article[data-article-nr="${current}"]`)
            if(article) window.scrollTo(window.scrollX, article.offsetTop-50)
            else current++
            break;
        }
        case 'ArrowDown':{
            if(current < 0){
                current = 0;
            }
            e.preventDefault()
            current++
            const article = document.querySelector(`.article[data-article-nr="${current}"]`)
            if(article) window.scrollTo(window.scrollX, article.offsetTop-50)
            else current--
            break;
        }
    }
})