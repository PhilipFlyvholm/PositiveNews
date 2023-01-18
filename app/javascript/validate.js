window.addEventListener('load', () => {
    const positive_button = document.getElementById('button-validate-positive')
    const negative_button = document.getElementById('button-validate-negative')
    const trash_button = document.getElementById('button-validate-trash')
    const article_container = document.getElementById('article-container')

    positive_button.addEventListener('click', () => {
        console.log("positive")
        setSentiment("positive")

    })

    negative_button.addEventListener('click', () => {
        console.log("negative")
        setSentiment("negative")
    })
    trash_button.addEventListener('click', () => {
        console.log("trash")
        //make a request to the server to delete the article on admin/validate/:id
        //then remove the last article from the container
        const article_id = article_container.lastElementChild.dataset.articleId
        const url = `/admin/validate/${article_id}`
        const xmlhttp = new XMLHttpRequest();
        xmlhttp.open("DELETE", url, true);
        xmlhttp.send();
        article_container.removeChild(article_container.lastElementChild)

    })

    window.addEventListener('keydown', (e) => {
        console.log(e.key)
        if (e.key.toLowerCase() === 'n') {
            setSentiment("negative")
        } else if (e.key.toLowerCase() === 'p') {
            setSentiment("positive")
        }
    })
    const setSentiment = (sentiment) => {
        //get the article id of the last article in the article container
        const article_id = article_container.lastElementChild.dataset.articleId
        const url = `/admin/validate/${article_id}/${sentiment}`
        const xmlhttp = new XMLHttpRequest();
        xmlhttp.open("PUT", url);
        xmlhttp.send();
        console.log("Updated", article_id, "to", sentiment)
        //remove the last article from the article container
        article_container.removeChild(article_container.lastElementChild)
    }
});


